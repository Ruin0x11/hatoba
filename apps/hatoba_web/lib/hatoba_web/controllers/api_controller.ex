defmodule HatobaWeb.ApiController do
  use HatobaWeb, :controller

  def status(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Hatoba.Queue.status |> Poison.encode!)
  end

  def add(conn, _params) do
    {status, body} =
      case conn.body_params do
        %{"items" => items} -> do_add(items)
        params -> {422, Poison.encode!(params)}
      end
    send_resp(conn, status, body)
  end

  defp do_add(item) do
    case Hatoba.Queue.add(item) do
      :ok -> {200, Poison.encode!(%{message: "ok"})}
      _   -> error("Could not add.")
    end
  end

  defp error(msg), do: {404, Poison.encode!(%{error: msg})}
end
