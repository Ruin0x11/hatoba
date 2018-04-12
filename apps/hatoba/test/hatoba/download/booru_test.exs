defmodule Hatoba.Download.BooruTest do
  use ExUnit.Case, async: false

  import Mock
  alias HTTPoison.Response

  setup_with_mocks([
    {HTTPoison, [], [get!: fn(url) ->
                      cond do
                        String.contains?(url, "post.json") -> response(200, metadata())
                        String.contains?(url, "tag.json") -> response(200, '[{"name": "", "type": "", "ambiguous": false}]')
                        url == "the_file" -> response(200, '')
                        true -> response(404)
                      end
                    end]},
    {HTTPoison, [], [get!: fn(_, _, _) ->
                      cond do
                        true -> response(404)
                      end
                    end]},
  ]) do
    {:ok, foo: "foo"}
  end

  def run(url) do
    Hatoba.Download.Task.async([Hatoba.Download.Booru, self(), "/tmp", url])
  end

  defp response(code, body \\ "") do
    %Response {
      body: body,
      status_code: code,
      headers: []
    }
  end

  test "provides progress" do
    %Task{pid: pid} = run("https://yande.re/post/show/12345")

    send pid, %HTTPoison.AsyncHeaders{headers: [{"Content-Length", "100"}]}
    send pid, %HTTPoison.AsyncChunk{chunk: String.duplicate("a", 50)}

    assert_receive {:progress, "the_file", 50.0}, 500
  end

  defp metadata, do: '[{"id": 0, "tags": "my_tag my_other_tag", "source": "my_source", "md5": "", "file_url": "the_file", "has_children": false, "parent_id": 0}]'

  test "provides metadata" do
    %Task{} = run("https://yande.re/post/show/12345")

    assert_receive {:metadata, "the_file",
                    %{md5: "",
                      original: "https://yande.re/post/show/12345",
                      source: "my_source",
                      tags: [%{ambiguous: false, name: "", type: ""},
                             %{ambiguous: false, name: "", type: ""}]}}, 500
  end

  test "exits on timeout" do
    {:ok, pid} = Hatoba.Download.Task.start([Hatoba.Download.Booru, self(), "/tmp", "https://yande.re/post/show/12345"])
    ref = Process.monitor(pid)

    send pid, %HTTPoison.Error{reason: {:closed, :timeout}}

    assert_receive {:DOWN, ^ref, :process, ^pid, {:failure, "Timed out."}}, 500
  end
end
