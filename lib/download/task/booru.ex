defmodule BooruPost do
  defstruct(
    id: nil,
    tags: nil,
    created_at: nil,
    updated_at: nil,
    creator_id: nil,
    approver_id: nil,
    author: nil,
    change: nil,
    source: nil,
    score: nil,
    md5: nil,
    file_size: nil,
    file_ext: nil,
    file_url: nil,
    is_shown_in_index: nil,
    preview_url: nil,
    preview_width: nil,
    preview_height: nil,
    actual_preview_width: nil,
    actual_preview_height: nil,
    sample_url: nil,
    sample_width: nil,
    sample_height: nil,
    sample_file_size: nil,
    jpeg_url: nil,
    jpeg_width: nil,
    jpeg_height: nil,
    jpeg_file_size: nil,
    rating: nil,
    is_rating_locked: nil,
    has_children: nil,
    parent_id: nil,
    status: nil,
    is_pending: nil,
    width: nil,
    height: nil,
    is_held: nil,
    frames_pending_string: nil,
    frames_pending: nil,
    frames_string: nil,
    frames: nil,
    is_note_locked: nil,
    last_noted_at: nil,
    last_commented_at: nil
  )
end

defmodule Hatoba.Download.Booru do
  @behaviour Hatoba.Download.Task

  def run(parent, outpath, arg) do
    {base, id} = arg |> base_and_id

    if id != nil do
      download(parent, outpath, arg, base, id)
    else
      send parent, {:failure}
    end
  end

  defp download(parent, outpath, url, base, id) do
    post = post_json(base, id)
    metadata = post
    |> Map.from_struct
    |> metadata(url)

    send parent, {:metadata, metadata}

    post
    |> Map.get(:file_url)
    |> HTTPotion.get(stream_to: self(), timeout: 5_000_000)

    receive_data(parent, outpath, total_bytes: :unknown, data: "")

    :success
  end

  defp receive_data(parent, outpath, total_bytes: total_bytes, data: data) do
    receive do
      %HTTPotion.AsyncHeaders{headers: h} ->
        {total_bytes, _} = h[:"Content-Length"] |> Integer.parse
        receive_data(parent, outpath, total_bytes: total_bytes, data: data)

      %HTTPotion.AsyncChunk{chunk: new_data} ->
        accumulated_data = data <> new_data
        accumulated_bytes = byte_size(accumulated_data)
        percent = accumulated_bytes / total_bytes * 100 |> Float.round(2)
        send parent, {:progress, percent}
        receive_data(parent, outpath, total_bytes: total_bytes, data: accumulated_data)

      %HTTPotion.AsyncEnd{} ->
        File.write!(outpath, data)

      %HTTPotion.AsyncTimeout{} ->
        send parent, {:failure, "Timed out."}

    end
  end

  defp post_json(base, id) do
    base
    |> URI.merge("/post.json?tags=id:#{id}")
    |> URI.to_string
    |> HTTPotion.get
    |> Map.get(:body)
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

  defp metadata(post, original) do
    %{tags: post.tags, md5: post.md5, source: post.source, original: original}
  end

  defp base_and_id(uri) do
    { base_uri(uri), post_id(uri) }
  end

  # TODO: duplicate
  defp base_uri(uri) do
    %{authority: authority, scheme: scheme} = URI.parse(uri)
    "#{scheme}://#{authority}"
  end
end
