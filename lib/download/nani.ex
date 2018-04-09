defmodule Hatoba.Nani do
  alias Porcelain.Result

  def source_type(data) do
    if valid_uri(data) do
      # ordering of this cond is important.
      # it should be ordered from most specific to most general.
      cond do
        is_youtube(data) -> :youtube_dl
        is_torrent(data) -> :torrent
        is_booru(data) -> :booru
        #is_magnet_link(data) -> :magnet
        true -> :unknown
      end
    else
      :unknown
    end
  end

  defp valid_uri(data) do
    %{:authority => auth} = URI.parse(data)
    auth != nil
  end

  defp is_youtube(uri) do
    Porcelain.shell("youtube-dl -g #{uri}").status == 0
  end

  defp is_booru(uri) do
    data = uri
    |> base_uri
    |> URI.merge("/posts.json")
    |> URI.to_string
    |> HTTPotion.get
    |> Map.from_struct
    Map.get(data, :status_code) == 200 && content_type(data) == "application/json"
  end

  defp is_torrent(uri) do
    uri
    |> HTTPotion.get
    |> Map.from_struct
    |> content_type == "application/x-bittorrent"
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
