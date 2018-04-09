defmodule Hatoba.NaniTest do
  use ExUnit.Case, async: false

  import Mock
  alias Porcelain.Result
  alias HTTPotion.Response
  alias HTTPotion.Headers

  ## lots of mocks, since content discerning interacts with web services which we can't determine
  ## the validity of in a pure manner
  setup_with_mocks([
    {Porcelain, [], [shell: fn(_) -> %Result{status: 1} end]},
    {HTTPotion, [], [get: fn(_) -> response(404) end]},
  ]) do
    {:ok, foo: "foo"}
  end

  defp response(code), do: %Response{status_code: code, headers: %Headers{ hdrs: %{} }}

  test "discerns youtube-dl source" do
    with_mock Porcelain, [shell: fn(_) -> %Result{status: 0} end] do
      assert Hatoba.Nani.source_type("https://www.youtube.com/watch?v=QbliRYZdJ4I") == :youtube_dl
      assert Hatoba.Nani.source_type("https://youtu.be/FI1NvBQfH9A") == :youtube_dl
      assert Hatoba.Nani.source_type("https://vimeo.com/263108265") == :youtube_dl
    end
    with_mock Porcelain, [shell: fn(_) -> %Result{status: 1} end] do
      assert Hatoba.Nani.source_type("https://www.google.com") == :unknown
      assert Hatoba.Nani.source_type("blah") == :unknown
    end
  end

  test "discerns booru" do
    with_mock HTTPotion, [get: fn(_) -> content_response("application/json") end] do
      assert Hatoba.Nani.source_type("https://danbooru.donmai.us/post/1234") == :booru
    end
    with_mock HTTPotion, [get: fn(_) -> response(404) end] do
      assert Hatoba.Nani.source_type("https://www.google.com") == :unknown
      assert Hatoba.Nani.source_type("blah") == :unknown
    end
  end

  test "discerns torrent URL" do
    with_mock HTTPotion, [get: fn(url) ->
                           if String.ends_with?(url, ".torrent") do
                             content_response("application/x-bittorrent")
                           else
                             content_response("text/html")
                           end
                         end] do
      assert Hatoba.Nani.source_type("https://nyaa.si/download/1.torrent") == :torrent
      assert Hatoba.Nani.source_type("https://jsonplaceholder.typicode.com/posts") == :unknown
    end
  end

  defp content_response(content_type) do
    %Response {
      status_code: 200,
      headers: %Headers { hdrs: %{ "content-type" => content_type } }
    }
  end

  test "discerns magnet link" do
    assert false
  end

  test "discerns image URL" do
    assert false
  end

  test "discerns image data" do
    assert false
  end

  test "fails discerning malformed URLs" do
    assert Hatoba.Nani.source_type("youtu.be/watch?v=QbliRYZdJ4I") == :unknown
  end
end
