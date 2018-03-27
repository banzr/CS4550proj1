defmodule Checker.GameBackup do
  use Agent

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def save(name, game) do
    Agent.update __MODULE__, fn state ->
      Map.put(state, name, game)
    end
  end

  def load(name) do
    Agent.get __MODULE__, fn state ->      
      Map.get(state, name)
    end
  end

  def game_list() do
    Agent.get __MODULE__, fn state ->
      :maps.filter(fn name,game -> Kernel.length(Map.keys(game.players)) < 2 && name != "164579235" end, state)
    end
  end
end
