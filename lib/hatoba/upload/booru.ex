defmodule Hatoba.Upload.Booru do
  @behaviour Hatoba.Upload.Task

  # only supports booru2
  def run(_parent, dl, _arg) do
    upload_post(dl)
    :success
  end

  def validate(_dl, _arg) do
    ## TODO: validate md5s
    :ok
  end

  # defp update_tags(dl) do
  #   resp = dl
  #   |> Map.get(:metadata)
  #   |> Enum.flat_map(&Map.values(&1))
  #   |> Enum.each(&HTTPotion.post())
  # end

  defp upload_post(dl) do
    url = Application.fetch_env!(:hatoba, :booru_url)
    resp = dl
    |> Hatoba.Download.files
    |> Enum.map(&form(&1, Map.get(dl, :metadata)))
    |> Enum.each(&HTTPoison.post(url, form(&1, Map.get(dl, :metadata))))
    IO.inspect resp
  end

  defp form(filepath, metadata) do
    file_metadata = metadata
    |> Path.split
    |> List.last
    |> (&Map.get(metadata, &1)).()
    %{ :upload =>
      %{
        :file => :hackney_multipart.encode_form([{:file, filepath}]),
        :rating => Map.get(file_metadata, :rating),
        :tags => tag_string(file_metadata)
      }
    }
  end

  defp tag_string(metadata) do
    tags = metadata
    |> Map.get(:tags)
    if Enum.empty?(tags) do
      "tagme"
    else
      tags
      |> Enum.map(&Map.get(&1, :name))
      |> Enum.join(" ")
    end
  end
end


#  finished: [
#    %{
#      dir: "AFA5171939B4E6B989E4803FB2D8D474CC7E5D42961DFA72887DDC0A7C7F600D",
#      filecount: 1,
#      id: 0,
#      metadata: %{
#        "yande.re%20123456%20ntype%20text.jpg" => %{
#          md5: "9a753a4d4c2abe8a36b64789b65d829f",
#          original: "https://yande.re/post/show/123456",
#          source: "",
#          tags: [
#            %{ambiguous: false, name: "ntype", type: 5},
#            %{ambiguous: false, name: "detexted", type: 0}
#          ]
#        }
#      },
#      output: ["yande.re%20123456%20ntype%20text.jpg"],
#      parent: #PID<0.224.0>,
#      pid: #PID<0.235.0>,
#      progress: %{"yande.re%20123456%20ntype%20text.jpg" => 100.0},
#      ref: #Reference<0.3069776818.1283981334.22616>,
#      status: :finished,
#      url: "https://yande.re/post/show/123456"
#    }
#  ],
