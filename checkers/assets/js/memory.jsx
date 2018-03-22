import React from 'react';
import ReactDOM from 'react-dom';
import { Button } from 'reactstrap';

export default function game_init(root, channel) {
  ReactDOM.render(<MemoryGame channel={channel}/>, root);
}

class MemoryGame extends React.Component {
  constructor(props) {
  super(props);
    this.channel = props.channel;
    this.state = { 
      // 1 and 3 for p1 piece and 2 and 4 for p2 piece, 0 is none
      board: [],
      //whose turn is it: 1 for p1 and 0 for p2
      turn: 1,
      selectedTile: -1,
      };
    this.channel.join()
      .receive("ok", this.gotView.bind(this))
      .receive("error", resp => { console.log("MemoryGame Unable to join", resp) });
  }

  gotView(view) {
    this.setState(view.game, this.checkBoard(view.game.reset));
  }

  sendClick(id) {
    this.channel.push("move", { id: id, board: this.state.board, selectedTile: this.state.selectedTile })
      .receive("ok", this.gotView.bind(this));
//    setTimeout(() => {
//      this.channel.push("timeout", { id: id, cards: this.state.cards })
//        .receive("ok", this.gotView.bind(this))
//    }, 500)
  }

  selectTile(id) {
    console.log("selected: "+id)
    let selected = this.state.selectedTile;
    let val = this.state.board[id];
    if (this.isValidSelect(id, val)) {
      console.log("setting tile "+id+" val "+val+" "+this.state.turn);
      this.setTile(id, val);
    } else if (selected != -1) {
      this.sendClick(id);
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

  //check if the move is allowed here to reduce
  //communication to and from server
  //if move is not allowed we abort it immediately
  handleClick(id) {
    let board = this.state.board;
    let selected = this.state.selectedTile;
    if (!isValidMove(selected, id)) {
      console.log("illegal move");
      return;
    }
    
    let isJump = isJumpMove(selected, id);
    
  }

  nextTurn() {
    return (this.state.turn == 1 ? 0 : 1);
  }

  checkBoard(flag) {
    let done = this.state.done;
    if (done >= 16 && flag) {
      alert("Board cleared! Generating new board!")
      this.restartGame();
    }
  }

  restartGame() {
    this.channel.push("reset", { cards: this.state.cards })
      .receive("ok", this.gotView.bind(this));
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
