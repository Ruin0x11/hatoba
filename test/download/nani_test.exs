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

  defp content_response(content_type, code \\ 200) do
    %Response {
      status_code: code,
      headers: %Headers { hdrs: %{ "content-type" => content_type } }
    }
  end

  defp response(code), do: content_response("text/html", code)

  test "discerns video" do
    with_mock Porcelain, [shell: fn(_) -> %Result{status: 0} end] do
      assert Hatoba.Nani.source_type("https://www.youtube.com/watch?v=QbliRYZdJ4I") == :video
      assert Hatoba.Nani.source_type("https://youtu.be/FI1NvBQfH9A") == :video
      assert Hatoba.Nani.source_type("https://vimeo.com/263108265") == :video
    end
    with_mock Porcelain, [shell: fn(_) -> %Result{status: 1} end] do
      assert Hatoba.Nani.source_type("https://www.google.com") == :unknown
      assert Hatoba.Nani.source_type("blah") == :unknown
    end
  end

  test "discerns booru" do
    with_mock HTTPotion, [get: fn(url) ->
                           if String.ends_with?(url, "post.json") do
                             content_response("application/json; charset=utf-8")
                           else
                             response(404)
                           end
                         end] do
      assert Hatoba.Nani.source_type("https://yande.re/posts/show/1234") == :booru
    end
  end

  test "discerns booru2" do
    with_mock HTTPotion, [get: fn(url) ->
                           if String.ends_with?(url, "posts.json") do
                             content_response("application/json; charset=utf-8")
                           else
                             response(404)
                           end
                         end] do
      assert Hatoba.Nani.source_type("https://danbooru.donmai.us/post/1234") == :booru2
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

  test "discerns magnet link" do
    assert Hatoba.Nani.source_type("magnet:?xt=urn:bith:ASDF&dn=Blah") == :magnet
  end

  test "discerns image URL" do
    with_mock HTTPotion, [get: fn(_) -> content_response("image/png") end] do
      assert Hatoba.Nani.source_type("https://www.w3.org/People/mimasa/test/imgformat/img/w3c_home.gif") == :image
    end
  end

  test "fails discerning malformed URLs" do
    assert Hatoba.Nani.source_type("blah") == :unknown
    assert Hatoba.Nani.source_type("youtu.be/watch?v=QbliRYZdJ4I") == :unknown
  end

  test "fails discerning unsupported URLs" do
    with_mock HTTPotion, [get: fn(_) -> response(200) end] do
      assert Hatoba.Nani.source_type("https://www.google.com") == :unknown
    end
  end
end
