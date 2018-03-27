defmodule CheckerWeb.GamesChannel do
  use CheckerWeb, :channel
  
  alias CheckerWeb.Game


  def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
      game = Checker.GameBackup.load(name) || Game.new()
      game = add_user(game, socket)
      socket = socket
      |> assign(:game, game)
      |> assign(:name, name)
      Checker.GameBackup.save(socket.assigns[:name], game)      

      game_list = Map.keys(Checker.GameBackup.game_list())
      send(self, {:after_join, name})

      {:ok, %{"join" => name, "game_list" => game_list}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def add_user(game, socket) do
    player_list = Map.keys(game.players)
    viewer_list = Map.keys(game.viewers)
    p_len = Kernel.length(player_list)+1
    v_len = Kernel.length(viewer_list)
    cur_player = socket.assigns[:user_id]
    cur_viewers = Map.keys(:maps.filter(fn _,v -> v == cur_player end, game.viewers))
    #it's a bit tricky here since 1 is for player one is 0 is for player 2
    cond do
      p_len == 1 ->
        %{game | players: Map.put_new(game.players, (rem p_len, 2), cur_player)}
      p_len == 2 && Map.get(game.players, 1) != cur_player ->
        %{game | players: Map.put_new(game.players, (rem p_len, 2), cur_player)}
      p_len >= 3 && Map.get(game.players, 0) != cur_player && Map.get(game.players, 1) != cur_player && Kernel.length(cur_viewers) == 0 ->
        %{game | viewers: Map.put_new(game.viewers, v_len, cur_player)}
      true -> game  
    end
  end

  def handle_info({:after_join, _name}, socket) do
    game = Checker.GameBackup.load(_name) || Game.new()    
    socket = socket
      |> assign(:game, game)
    broadcast socket, "player:joined", %{game: Game.client_view(game)}   

    {:noreply, socket}
  end  

  def handle_in("move", %{"id" => id, "selectedTile" => selectedTile}, socket) do
    game = Game.handle_click(Checker.GameBackup.load(socket.assigns[:name]), id, selectedTile)
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

  def handle_in("reset", %{}, socket) do
    game = Checker.GameBackup.load(socket.assigns[:name])
    game = Game.new(game)

    Checker.GameBackup.save(socket.assigns[:name], game)
    socket = assign(socket, :game, game)
    broadcast socket, "player:joined", %{game: Game.client_view(game)}

    {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
