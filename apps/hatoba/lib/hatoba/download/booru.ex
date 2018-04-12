defmodule BooruTag do
  defstruct [:name, :type, :ambiguous]
end

defmodule BooruPost do
  defstruct [:id, :tags, :source, :rating, :md5, :file_url, :has_children, :parent_id]
end

defmodule Hatoba.Download.Booru do
  @behaviour Hatoba.Download.Task

  def run(parent, outpath, arg) do
    {base_uri, id} = arg |> base_uri_and_id

    if id != nil do
      download(parent, outpath, arg, base_uri, id)
    else
      Process.exit(self(), {:failure, "No such id"})
    end
  end

  defp download(parent, outpath, url, base_uri, id) do
    post = post_json(base_uri, id)
    metadata = post
    |> Map.from_struct
    |> metadata(base_uri, url)

    url = post
    |> Map.get(:file_url)

    if url == nil do
      Process.exit(self(), {:failure, "Bad URL or network error."})
    end

    filename = url
    |> Path.split
    |> List.last
    |> URI.decode

    send parent, {:metadata, filename, metadata}

    HTTPoison.get!(url, %{}, stream_to: self(), timeout: 5_000_000)

    receive_data(parent, filename, outpath, total_bytes: :unknown, data: "")
  end

  defp receive_data(parent, filename, outpath, total_bytes: total_bytes, data: data) do
    receive do
      %HTTPoison.AsyncHeaders{headers: h} ->
        {total_bytes, _} = h |> Hatoba.Nani.get_header("Content-Length") |> Integer.parse
        receive_data(parent, filename, outpath, total_bytes: total_bytes, data: data)

      %HTTPoison.AsyncChunk{chunk: new_data} ->
        accumulated_data = data <> new_data
        accumulated_bytes = byte_size(accumulated_data)
        percent = accumulated_bytes / total_bytes * 100 |> Float.round(2)
        send parent, {:progress, filename, percent}
        receive_data(parent, filename, outpath, total_bytes: total_bytes, data: accumulated_data)

      %HTTPoison.AsyncEnd{} ->
        [outpath, filename]
        |> Path.join
        |> File.write!(data)

        Process.exit(self(), {:success, [filename]})

      %HTTPoison.Error{reason: {:closed, :timeout}} ->
        Process.exit(self(), {:failure, "Timed out."})

    end
  end

  defp post_json(base_uri, id) do
    base_uri
    |> req("/post.json?tags=id:#{id}")
    |> Poison.decode!(as: [%BooruPost{}])
    |> List.first
  end

  defp post_id(url) do
    {id, ""} = url
    |> Path.split
    |> List.last
    |> Integer.parse
    id
  end

  defp metadata(post, base_uri, original) do
    %{tags: all_tag_jsons(base_uri, post.tags), md5: post.md5, source: post.source, original: original}
  end

  defp all_tag_jsons(base_uri, tags) do
    tags
    |> String.split(" ")
    |> Enum.map(fn(t) -> tag_json(base_uri, t) |> Map.from_struct end)
  end

  defp tag_json(base_uri, tag) do
    base_uri
    |> req("/tag.json?name=#{tag}")
    |> Poison.decode!(as: [%BooruTag{}])
    |> List.first
  end

  defp req(base_uri, endpoint) do
    base_uri
    |> URI.merge(endpoint)
    |> URI.to_string
    |> HTTPoison.get!
    |> Map.get(:body)
  end

  defp base_uri_and_id(uri) do
    { base_uri(uri), post_id(uri) }
  end

  # FIXME: duplicate
  defp base_uri(uri) do
    %{authority: authority, scheme: scheme} = URI.parse(uri)
    "#{scheme}://#{authority}"
  end
end
