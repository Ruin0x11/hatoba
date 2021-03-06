defmodule Hatoba.Nani do

  ## TODO: cache known domains that procure types of content, like booru/youtube
  ## will reduce roundtrip time for content detection

  def source_type(data) do
    if valid_uri(data) do
      # ordering of this cond is important.
      # it should be ordered from most specific to most general.
      cond do
        is_magnet_link(data) -> :torrent
        is_image_uri(data) -> :image
        is_torrent(data) -> :torrent
        is_booru(data) -> :booru
        is_booru2(data) -> :booru2
        is_video(data) -> :video
        true -> :unknown
      end
    else
      :unknown
    end
  end

  defp valid_uri(data) do
    %{:scheme => scheme} = URI.parse(data)
    scheme != nil
  end

  defp is_video(uri) do
    auth = uri
    |> URI.parse
    |> Map.get(:authority)
    Enum.member?(["youtu.be", "www.youtube.com"], auth) || ytdl_responds(uri)
  end

  # bizarrely, this detects urls with extensions like .torrent as "direct video urls".
  defp ytdl_responds(uri), do: Porcelain.shell("youtube-dl -g --no-warnings #{uri}").status == 0

  defp is_booru2(uri), do: has_posts_api(uri, "/posts.json") && has_post_id(uri)
  defp is_booru(uri), do: has_posts_api(uri, "/post.json") && has_post_id(uri)

  defp has_posts_api(uri, endpoint) do
    resp = uri
    |> base_uri
    |> URI.merge(endpoint)
    |> URI.to_string
    |> HTTPoison.head

    case resp do
      {:ok, resp} ->
        data = resp
        |> Map.from_struct
        Map.get(data, :status_code) == 200
        && String.contains?(content_type(data), "application/json")
      _ -> false
    end
  end

  defp has_post_id(uri), do: Regex.match?(~r/[0-9]+$/, uri)

  defp is_torrent(uri) do
    resp = uri
    |> HTTPoison.head

    case resp do
      {:ok, resp} ->
        resp
        |> Map.from_struct
        |> content_type == "application/x-bittorrent"
      _ -> false
    end
  end

  defp is_magnet_link(uri) do
    uri
    |> URI.parse
    |> Map.get(:scheme) == "magnet"
  end

  defp is_image_uri(uri) do
    resp = uri |> HTTPoison.head

    case resp do
      {:ok, resp} ->
        resp
        |> content_type
        |> (&(Enum.member?(["image/png", "image/jpeg", "image/gif"], &1))).()
      _ -> false
    end
  end

  defp content_type(response) do
    response
    |> Map.get(:headers)
    |> get_header("Content-Type")
  end

  def get_header(headers, key) do
    headers
    |> Enum.filter(fn({k, _}) -> k == key end)
    |> hd
    |> elem(1)
  end

  defp base_uri(uri) do
    %{authority: authority, scheme: scheme} = URI.parse(uri)
    "#{scheme}://#{authority}"
  end
end
