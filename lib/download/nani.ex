defmodule Hatoba.Nani do
  alias Porcelain.Result

  def source_type(data) do
    if valid_uri(data) do
      # ordering of this cond is important.
      # it should be ordered from most specific to most general.
      cond do
        is_magnet_link(data) -> :magnet
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
    # bizarrely, this detects urls with extensions like .torrent as "direct video urls".
    Porcelain.shell("youtube-dl -g --no-warnings #{uri}").status == 0
  end

  defp is_booru2(uri), do: has_posts_api(uri, "/posts.json")
  defp is_booru(uri), do: has_posts_api(uri, "/post.json")

  defp has_posts_api(uri, endpoint) do
    data = uri
    |> base_uri
    |> URI.merge(endpoint)
    |> URI.to_string
    |> HTTPotion.get
    |> Map.from_struct
    Map.get(data, :status_code) == 200 && String.contains?(content_type(data),"application/json")
  end

  defp is_torrent(uri) do
    uri
    |> HTTPotion.get
    |> Map.from_struct
    |> content_type == "application/x-bittorrent"
  end

  defp is_magnet_link(uri) do
    uri
    |> URI.parse
    |> Map.get(:scheme) == "magnet"
  end

  defp is_image_uri(uri) do
    content_type = uri
    |> HTTPotion.get
    |> content_type
    Enum.any?(["image/png",
               "image/jpeg",
               "image/gif"], fn(s) -> content_type == s end)
  end

  defp content_type(response) do
    response
    |> Map.get(:headers)
    |> Map.from_struct
    |> Kernel.get_in([:hdrs, "content-type"])
  end

  defp base_uri(uri) do
    %{authority: authority, scheme: scheme} = URI.parse(uri)
    "#{scheme}://#{authority}"
  end
end
