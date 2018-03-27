defmodule CheckerWeb.PageController do
  use CheckerWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def game(conn, params) do
    render conn, "game.html", [game: params["game"], user_id: params["user_id"]]
  end
end
