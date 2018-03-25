defmodule CheckerWeb.Router do
  use CheckerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CheckerWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/game/:game/:user_id", PageController, :game
  end

  # Other scopes may use custom stacks.
  # scope "/api", CheckerWeb do
  #   pipe_through :api
  # end
end
