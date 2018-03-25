defmodule CheckerWeb.PageController do
  use CheckerWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def game(conn, params) do
    IO.puts("CONN PARAM #{Kernel.inspect(params)}")
    render conn, "game.html", [game: params["game"], user_id: params["user_id"]]
  end
end
