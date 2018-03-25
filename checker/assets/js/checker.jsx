import React from 'react';
import ReactDOM from 'react-dom';
import { Button } from 'reactstrap';

export default function game_init(root, channel, player) {
  ReactDOM.render(<CheckerGame channel={channel} player={player}/>, root);
}

class CheckerGame extends React.Component {
  constructor(props) {
  super(props);
    this.channel = props.channel;
    this.state = { 
      // 1 and 3 for p1 piece and 2 and 4 for p2 piece, 0 is none
      board: [],
      //whose turn is it: 1 for p1 and 0 for p2
      turn: 1,
      selectedTile: -1,
      //cannot change selectedTile, for continuous jumping
      force: false,
      winner: -1,
      players: [],
      viewers: []
      };
    this.player = props.player;
    this.channel.join()
      .receive("ok", view => {
        console.log("joined channel");
        this.gotView(view.game);
        this.channelHandlers(this.channel);
      })
      .receive("error", resp => { console.log("CheckerGame Unable to join", resp) });
  }

  gotView(game) {
    this.setState(game, this.checkBoard());
  }

  channelHandlers(channel) {
    channel.on("player:position", ({game: game}) => {
      this.channel.push("update_pos", {}); 
      this.gotView(game);
    });
    channel.on("player:joined", ({game: game}) => {
      _.map(game.players, (p, ii) => {
        console.log("PLAYER "+ii+" "+p);
      });
      console.log("SUP?");
      _.map(game.viewers, (v, ii) => {
        console.log("VIEWER "+ii+" "+v);
      });
      this.gotView(game);
    });
    console.log("RECEIVED UPDATE");
  }

  componentDidUpdate(prevProps, prevState) {
    this.checkBoard();
  }

  checkBoard() {
    let board = this.state.board;
    let p1 = board.filter((val) => {
      return val == 1 || val == 3;
    });
    let p2 = board.filter((val) => {
      return val == 2 || val == 4;
    });
    console.log("P1 "+p1.length+" P2 "+p2.length);
    if (p1.length == 0 && p2.length != 0 && this.state.winner == -1) {
      alert("Player 2 won")
      this.restartGame(0);
    } else if (p2.length == 0 && p1.length != 0 && this.state.winner == -1) {
      alert("Player 1 won")
      this.restartGame(0)
    }
  }

  sendClick(id) {
    this.channel.push("move", { id: id, selectedTile: this.state.selectedTile })
  }

  selectTile(id) {
    let selected = this.state.selectedTile;
    let val = this.state.board[id];
    console.log("THIS PLAYER "+this.player+" "+this.state.turn%2);
    console.log("THIS TURN PLAYER "+this.state.players[0]);
    if (this.player == this.state.players[this.state.turn%2]) {
      if (this.isValidSelect(id, val) && !this.state.force) {
        this.setTile(id, val);
      } else if (selected != -1) {
        this.sendClick(id);
      }
    }
  }

  isValidSelect(id, val) {
    if (val == 0) {
      return false;
    }
    return val%2 == this.state.turn%2;
  }

  setTile(id, val) {
    this.setState({selectedTile: id});
  }

  restartGame(winner) {
    this.channel.push("reset", {})
      .receive("ok", view => {
        this.gotView(view.game)
      });
  }

  render() {
    return (
      <div>
        <Button className="col" onClick={this.restartGame.bind(this)}>Restart!</Button>
        <div className="col">
          &nbsp;
        </div>
        <div>Player {this.state.turn}</div>
        <Board board={this.state.board} sendClick={this.selectTile.bind(this)} selectedTile={this.state.selectedTile}/>
      </div>
    );
  }
}

function Board(params) {
  let board = params.board
  let tilesSet = _.map(board, (val, ii) => {
    return <Tile id={ii} val={val} key={ii} sendClick={params.sendClick} selectedTile={params.selectedTile}/>;
  });
  return (
    <div className="board">
      {tilesSet}
    </div>
  );
}

function Tile(params) {
  let id = params.id
  let color = (id%2 + Math.floor(id/8)) % 2 == 0 ? "red" : "black";
  let selection = (id == params.selectedTile ? " selected" : "");
  let classes = "tile " + color + selection;
  function tileClicked(e) {
    params.sendClick(id);
  }
  return (
    <div className={classes} onClick={tileClicked}>
      {params.val != 0 &&
        <Piece val={params.val} />
      }
    </div>
  );
}

function Piece(params) {
  let val = params.val;
  let classes = "";
  if (val%2 == 1) {
    classes += "player-one";
  } else if (val%2 == 0) {
    classes += "player-two";
  }
  if (val > 2) {
    classes += " king";
  }
  return (
    <div className={classes}></div>
  )
}

function Card(params) {
  let card = params.card
  let text = params.card.flipped? params.card.value : "?"
  text = params.card.matched? "✓" : text
  let id = params.id
  function cardClicked(e) {
    params.sendClick(id)
  }

  return (
    <div id={id} className="card" onClick={cardClicked}>
      {text}
    </div>
  );
}
