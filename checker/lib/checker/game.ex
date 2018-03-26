defmodule CheckerWeb.Game do
  @moduledoc """
  Checker keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def new(game) do
    %{
      board: new_board(),
#who turn is it, true = 1, false = 0/2
      turn: 1,
      selectedTile: -1,
      force: false,
      winner: -1,
      players: game.players,
      viewers: game.viewers
    }
  end

  def new() do
    %{
      board: new_board(),
#who turn is it, true = 1, false = 0/2
      turn: 1,
      selectedTile: -1,
      force: false,
      winner: -1,
      players: %{},
      viewers: %{}
    }
  end

  def client_view(game) do 
    game
  end

  def isMoveValid(board, selected, id) do
    cur_val = Enum.at(board,selected)
    result = %{ res: false, mid_id: -1}
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
#check if king, kings are treated differently
      new_val == 0 && cur_val > 2 ->
        if (Kernel.abs(new_row - cur_row) == 1 && Kernel.abs(new_col - cur_col) == 1) do
          %{ result | res: true }
        else
          if (Kernel.abs(new_row - cur_row) == 2 && Kernel.abs(new_col - cur_col) == 2) do
            mid_col = div (cur_col + new_col),2
            mid_row = div (cur_row + new_row),2
            mid_id = mid_col + mid_row * 8
            if ((rem Enum.at(board, mid_id), 2) != (rem cur_val, 2)) do
              %{ result | res: true, mid_id: mid_id}
            end
          end
        end
        
#normal piece
      new_val == 0 ->
#allow move to the next row only
        if (new_row == (cur_row + next_tile)) do
#allow move diagonally only
          if (new_col == cur_col + next_tile || new_col == cur_col - next_tile) do
            %{ result | res: true}
          end        
#else we check if it's a jump and it's a valid jump
        else
          if (new_row == (cur_row + 2 * next_tile)) do
            if (new_col == cur_col + 2 * next_tile) do 
              mid_id = (cur_col + next_tile) + (cur_row + next_tile) * 8
              mid_val = Enum.at(board, mid_id)              
              valid = mid_val != 0 && (rem mid_val,2) != (rem cur_val,2)
              if (valid) do
                %{ result | res: valid, mid_id: mid_id}
              else
                result
              end
            else
              if (new_col == cur_col - 2 * next_tile) do
                mid_id = (cur_col - next_tile) + (cur_row + next_tile) * 8
                mid_val = Enum.at(board, mid_id)
                valid = mid_val != 0 && (rem mid_val,2) != (rem cur_val,2)
                if (valid) do
                  %{ result | res: valid, mid_id: mid_id}
                else
                  result
                end
              else
                %{ result | res: false}
              end
            end
          end
        end
      true -> %{ result | res: false}
    end      
  end

  def anyValidMove(board, selected) do
    result = false
    cur_val = Enum.at(board, selected)
    next_tile = 1
    if ((rem cur_val,2) == 0) do
      next_tile = -1
    end
    cur_col = rem selected, 8
    cur_row = div selected, 8
    up_row = cur_row + next_tile
    left_col = cur_col + next_tile
    right_col = cur_col - next_tile
    d_up_row = cur_row + 2 * next_tile
    up_left_id = left_col + up_row * 8
    up_right_id = right_col + up_row * 8
    down_row = cur_row - next_tile
    down_left_id = left_col + down_row * 8
    down_right_id = right_col + down_row * 8
    if (-1 < up_row && up_row < 8) do
      if (left_col < 8 && left_col > -1) do
        result = result || Enum.at(board, up_left_id) == 0
      else
        if (right_col < 8 && right_col > -1) do
          result = result || Enum.at(board, up_right_id) == 0
        end
      end
#king case
    else
      if (-1 < down_row && down_row < 8) do
        if (left_col < 8 && left_col > -1) do
          result = result || Enum.at(board, down_left_id) == 0
        else
          if (right_col < 8 && right_col > -1) do
            result = result || Enum.at(board, down_right_id) == 0
          end
        end
      end
    end
    result
  end

  def anyValidJump(board, selected) do
    result = false
    cur_val = Enum.at(board, selected)
    next_tile = 1
    if ((rem cur_val,2) == 0) do
      next_tile = -1
    end
    cur_col = rem selected, 8
    cur_row = div selected, 8
    up_row = cur_row + next_tile
    left_col = cur_col + next_tile
    right_col = cur_col - next_tile
    d_up_row = cur_row + 2 * next_tile
    d_left_col = cur_col + 2 * next_tile
    d_right_col = cur_col - 2 * next_tile
    up_left_id = left_col + up_row * 8
    up_right_id = right_col + up_row * 8
    down_row = cur_row - next_tile
    d_down_row = cur_row - 2 * next_tile
    down_left_id = left_col + down_row * 8
    down_right_id = right_col + down_row * 8
#make sure the up_col is not out of bound
    if (-1 < up_row && up_row < 8 && 8 > d_up_row && d_up_row > -1) do
      if (-1 < left_col && left_col < 8 && -1 < d_left_col && d_left_col < 8) do
#then we check if their values is different
        if (Enum.at(board, up_left_id) != 0 && (rem Enum.at(board, up_left_id), 2) != (rem cur_val, 2)) do
  #check if the diag tile after that is empty
          result = result || Enum.at(board, (d_left_col + d_up_row * 8)) == 0
        end
      end
      if (8 > right_col && right_col > -1 && -1 < d_right_col && d_right_col < 8) do
        if (Enum.at(board, up_right_id) != 0 && (rem Enum.at(board, up_right_id), 2) != (rem cur_val, 2)) do
  #check if the diag tile after that is empty
          result = result || Enum.at(board, (d_right_col + d_up_row * 8)) == 0
        end
      end 
#if this piece is King
      if (cur_val > 2) do
        if (-1 < down_row && down_row < 8 && -1 < d_down_row && d_down_row < 8) do
          if (-1 < left_col && left_col < 8 && -1 < d_left_col && d_left_col < 8) do
  #then we check if their values is different
            if (Enum.at(board, down_left_id) != 0 && (rem Enum.at(board, down_left_id), 2) != (rem cur_val, 2)) do
    #check if the diag tile after that is empty
              result = result || Enum.at(board, (d_left_col + d_down_row * 8)) == 0
            end
          end
          if (8 > right_col && right_col > -1 && -1 < d_right_col && d_right_col < 8) do
            if (Enum.at(board, down_right_id) != 0 && (rem Enum.at(board, down_right_id), 2) != (rem cur_val, 2)) do
    #check if the diag tile after that is empty
              result = result || Enum.at(board, (d_right_col + d_down_row * 8)) == 0
            end
          end
        end
      end
    end
    result
  end

  def handle_click(game, id, selected) do 
    board = game.board
    map_board = Stream.zip(Stream.iterate(0, &(&1+1)), board) |> Enum.into(%{})
    cur_pieces = :maps.filter(fn k,v -> v > 0 && (rem v, 2) == (rem game.turn, 2) end, map_board)
    valid_moves = :maps.filter(fn k, v -> anyValidMove(board, k) end, cur_pieces)
    valid_jumps = :maps.filter(fn k,v -> anyValidJump(board, k) end, cur_pieces)
  
    cur_val = Enum.at(board, selected)
    if (Kernel.length(Map.keys(valid_jumps)) == 0 && Kernel.length(Map.keys(valid_moves)) == 0) do
      new_turn = (rem game.turn, 2) + 1
      %{ game | winner: new_turn }
    else 
      if (Kernel.length(Map.keys(valid_jumps)) > 0) do
        if (Map.has_key?(valid_jumps, selected)) do
          process_move(game, id, selected)
        else
          game
        end
      else
        process_move(game, id, selected)
      end
    end
  end

  def process_move(game, id, selected) do
    board = game.board
    cur_val = Enum.at(board, selected)
    result = isMoveValid(board, selected, id)
    if (!result[:res]) do
      game
    else 
      new_board = update_board(board, id, selected, result[:mid_id], cur_val)
      valid_jump = anyValidJump(new_board, id)
      if (game.force && result[:mid_id] == -1) do
        game
      else
        if(result[:mid_id] != -1 && valid_jump) do
          %{ game | board: new_board, selectedTile: id, force: true}
        else
          new_turn = (rem game.turn, 2) + 1
          %{game | board: new_board, turn: new_turn, selectedTile: -1, force: false}
        end
      end
    end
  end

  def update_board(board, id, selected, mid_id, cur_val) do
    new_row = div id, 8
    if (new_row == ((rem cur_val,2) * 7)) do
      cur_val = cur_val + 2
    end
    board = List.replace_at(board, id, cur_val)
    board = List.replace_at(board, selected, 0)
    if (mid_id != -1) do
      board = List.replace_at(board, mid_id, 0)
    end
    board
  end

  def new_board() do
    board = [
      0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0,
      0, 1, 0, 1, 0, 1, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 0,
      0, 2, 0, 2, 0, 2, 0, 0,
      2, 0, 2, 0, 2, 0, 2, 0,
      0, 2, 0, 2, 0, 2, 0, 0,
      2, 0, 2, 0, 2, 0, 2, 0 
    ]
    board
  end
end
