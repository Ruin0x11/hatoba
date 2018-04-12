defmodule HatobaWeb.PageController do
  use HatobaWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
