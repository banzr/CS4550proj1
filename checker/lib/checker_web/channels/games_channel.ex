defmodule CheckerWeb.GamesChannel do
  use CheckerWeb, :channel
  
  alias CheckerWeb.Game

  def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
      game = Checker.GameBackup.load(name) || Game.new()
      socket = socket
      |> assign(:game, game)
      |> assign(:name, name)
      Checker.GameBackup.save(socket.assigns[:name], game)
      {:ok, %{"join" => name, "game" => Game.client_view(game)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("move", %{"id" => id, "selectedTile" => selectedTile}, socket) do
    game = Game.handle_click(socket.assigns[:game], id, selectedTile)
    Checker.GameBackup.save(socket.assigns[:name], game)
    socket = assign(socket, :game, game)
    broadcast socket, "player:position", %{game: Game.client_view(game)}
    {:noreply, socket}
  end

  def handle_in("update_pos", %{}, socket) do
    game = Checker.GameBackup.load(socket.assigns[:name])
    socket = assign(socket, :game, game)
    {:noreply, socket}
  end

  def handle_in("timeout", %{}, socket) do
    game = Game.handle_timeout(socket.assigns[:game])
    socket = assign(socket, :game, game)
    {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end

  def handle_in("reset", %{}, socket) do
    game = Game.new()
    socket = assign(socket, :game, game)
    {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end
    
  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
