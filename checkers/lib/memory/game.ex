defmodule MemoryWeb.Game do
  @moduledoc """
  Memory keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def new() do
    %{
      board: new_board(),
#who turn is it, true = 1, false = 0/2
      turn: 1,
      selectedTile: -1 
    }
  end

  def client_view(game) do
    board = game.board
    %{
      board: board,
      turn: game.turn,
      selectedTile: -1
    }
  end

  def isMoveValid(board, selected, id) do
    cur_val = Enum.at(board,selected)
    result = %{ res: true, mid_id: -1}
    next_tile = 1
    if ((rem cur_val,2) == 0) do
      next_tile = -1
    end
    cur_col = rem selected, 8
    cur_row = div selected, 8
    new_val = Enum.at(board,id)
    new_col = rem id, 8
    new_row = div id, 8
    cond do
      new_val == 0 ->
        IO.puts("#{cur_col} #{new_col}")
#TODO add check for limit of the board
#allow move to the next row only
        if (new_row == (cur_row + next_tile)) do
#allow move diagonally only
          if (new_col == cur_col + next_tile || new_col == cur_col - next_tile) do
            result
          end        
#else we check if it's a jump and it's a valid jump
        else
          if (new_row == (cur_row + 2 * next_tile)) do
            if (new_col == cur_col + 2 * next_tile) do 
              IO.puts("jump")
              mid_id = (cur_col + next_tile) + (cur_row + next_tile) * 8
              mid_val = Enum.at(board, mid_id)              
              valid = mid_val != 0 && (rem mid_val,2) != (rem cur_val,2)
              %{ result | res: valid, mid_id: mid_id}
            else
              if (new_col == cur_col - 2 * next_tile) do
                IO.puts("jump -1")
                mid_id = (cur_col - next_tile) + (cur_row + next_tile) * 8
                mid_val = Enum.at(board, mid_id)
                valid = mid_val != 0 && (rem mid_val,2) != (rem cur_val,2)
                %{ result | res: valid, mid_id: mid_id}
              else
                %{ result | res: false}
              end
            end
          end
        end
      true -> %{ result | res: false}
    end      
  end

  def anyValidJump(board, selected) do

  end

  def handle_click(game, id, selected) do 
    board = game.board
    cur_val = Enum.at(board, selected)
    result = isMoveValid(board, selected, id)
    if (!result[:res]) do
      IO.puts("Illegal move")
      game
    else 
      IO.puts("Yay")
      new_board = update_board(board, id, selected, result[:mid_id], cur_val)
      new_turn = (rem game.turn, 2) + 1
      %{game | board: new_board, turn: new_turn, selectedTile: -1}
    end
  end

  def update_board(board, id, selected, mid_id, cur_val) do    
    board = List.replace_at(board, id, cur_val)
    board = List.replace_at(board, selected, 0)
    if (mid_id != -1) do
      board = List.replace_at(board, mid_id, 0)
    end
    board
  end
@doc """
    cards = game.cards
    flip = game.flip
    first = game.first
    done = game.done
    clicked = game.clicked
    len = Kernel.map_size(flip)
    cond do
      len < 1 ->
        fl = %{a: cards[id]}
        newCard = %{cards[id] | flipped: true}

        new_cards = update_card(cards, id, newCard)
        %{game | cards: new_cards, flip: fl, first: id, done: done, clicked: clicked + 1, reset: false}
      len == 1 && !(cards[id] |> Map.get(:flipped)) ->
        firstCard = flip |> Map.get(:a) |> Map.get(:value)
        new_card = cards[id]
        fl = Map.put(flip, :b, cards[id])
        if (firstCard == (new_card |> Map.get(:value))) do
          new_first_card = %{cards[first] | flipped: true, matched: true}
          new_card = %{new_card | matched: true}
          done = done + 2
          cards = update_card(cards, first, new_first_card)
        end 
        new_card = %{new_card | flipped: true}
        
        cards = update_card(cards, id, new_card)
        %{game | cards: cards, flip: fl, first: nil, done: done, clicked: clicked + 1, reset: false}      
      true ->
        game 
    end
  end
"""

  def handle_timeout(game) do
    cards = game.cards
    if (Kernel.map_size(game.flip) == 2) do
      new_cards = Enum.into(Enum.map(cards, fn {k, v} ->
        if !(v |> Map.get(:matched) == true) do         
          {k, %{v | flipped: false}}
        else
          {k, v}
        end
      end), %{})
      fl = %{}
      first = nil
      %{game | cards: new_cards, flip: fl, first: first, reset: true}
    else
      %{game | reset: true}
    end
  end

  def update_card(cards, id, newCard) do
    Enum.into(Enum.map(cards, fn {k, v} ->
      if k == id do
        {k, newCard}
      else
        {k, v}
      end
    end), %{})
  end

  def new_board() do
    board = [
      0, 1, 0, 1, 0, 1, 0, 1,
      1, 0, 1, 0, 1, 0, 1, 0,
      0, 1, 0, 1, 0, 1, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0,
      2, 0, 2, 0, 2, 0, 2, 0,
      0, 2, 0, 2, 0, 2, 0, 2,
      2, 0, 2, 0, 2, 0, 2, 0 
    ]
    board
  end
end
