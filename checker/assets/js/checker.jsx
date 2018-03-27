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
      viewers: [],
      };
    this.player = props.player;
    this.channel.join()
      .receive("ok", view => {
        this.gotView(view.game);
        this.channelHandlers(this.channel);
      })
      .receive("error", resp => { console.log("CheckersGame Unable to join", resp) });
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
    if (this.state.winner != -1) {
      alert("Player "+this.state.winner+" won");
      this.restartGame()
    }
    else if (p1.length == 0 && p2.length != 0 && this.state.winner == -1) {
      alert("Player 2 won")
      this.restartGame();
    } else if (p2.length == 0 && p1.length != 0 && this.state.winner == -1) {
      alert("Player 1 won")
      this.restartGame()
    }
  }

  sendClick(id) {
    this.channel.push("move", { id: id, selectedTile: this.state.selectedTile })
  }

  selectTile(id) {
    let selected = this.state.selectedTile;
    let val = this.state.board[id];
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

  restartGame() {
      if (this.state.players[0] == this.player || this.state.players[1] == this.player) {
          this.channel.push("reset", {})
              .receive("ok", view => {
                  this.gotView(view.game)
              });
      }
  }

  render() {
    return (

      <div>
      <nav className="navbar navbar-light justify-content-between navbar-light text-dark chkr-nav">
          <a className="navbar-brand">
              <div className="form-inline">
              <img src="/images/checkers_icon.png" width="56" height="56" className="d-inline-block align-top" alt="">

              </img>
                  &nbsp;
                  <h1>Checkers</h1></div></a>
          <form className="form-inline">

              &nbsp;&nbsp;
              <Button className="col btn btn-danger" onClick={this.restartGame.bind(this)}>
                  <i className="fa fa-refresh" aria-hidden="true"></i>&nbsp;Restart
              </Button>
          </form>

      </nav>&nbsp;
          <div className="jumbotron playmat">
              <div className="row">
              <div className="col-1">

                  <h6>Current Turn: <br></br> <h4><span className="badge badge-primary">
                      { <CurrentPlayer state={this.state} /> }</span></h4></h6>

                  <h6>Game: <br></br> <h4><span className="badge badge-primary"> {gameName} </span></h4></h6>

                  <h6>Viewers: <br></br> </h6>
                      <ViewerList state={this.state} />

              </div>
              <div className="col-9">
        <Board board={this.state.board} sendClick={this.selectTile.bind(this)} selectedTile={this.state.selectedTile}/>
              </div>
              </div>
          </div>
      </div>

    );
  }
}


function CurrentPlayer(params) {
    let state = params.state;
    let curr_plyr =  state.players[(state.turn - 1) ? 0 : 1];
    return (! curr_plyr) ? "Awaiting match" : curr_plyr;
}

function ViewerList(params) {
    let vs = Object.values(params.state.viewers);
    let players = Object.values(params.state.players);

    let vs_set = new Set(vs);
    players.forEach(function (player) {
        vs_set.delete(player);
    });

    let views = Array.from(vs_set);
    console.log("List of viewers",vs);
    console.log("set of viewers",vs_set);
    if (!vs.length) { views = ["No viewers"] };

    let listItems = _.map(views, (val, ii) => {
        return <li className="list-group-item list-group-item-primary active" key={ii}> {val}</li>;
    });
    return (
        <h6><ul className="list-group" id="viewer_list">{listItems}</ul></h6>
    );
}

function Board(params) {
  let board = params.board;
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
  let id = params.id;
  let color = (id%2 + Math.floor(id/8)) % 2 == 0 ? "red" : "black";
  let selection = (id == params.selectedTile ? " selected" : "");

  //$('tile').css('height', size / 10).css('width', size / 10);
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
