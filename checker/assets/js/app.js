// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

import game_init from "./checker";





function form_init() {
  let channel = socket.channel("games:164579235", {user_id: "Unknown form_init"});

  channel.join()
         .receive("ok", resp => {
             console.log("Joined successfully", resp.game_list);

    let gl = resp.game_list.slice(0);

    if (!gl.length) { gl = new Array("No available games...") }

    (gl).forEach(function (game) {

        let list_elem = document.createElement("li");
        let a_elem = document.createElement("a");
        list_elem.setAttribute("class", "list-group-item");
        list_elem.appendChild(document.createTextNode(game.toString()));

        a_elem.setAttribute("href", "#");
        a_elem.setAttribute("onclick", "setGame(\"" + game.toString() + "\")");

        a_elem.appendChild(list_elem);

        document.getElementById('game_list').appendChild(a_elem);


    })

         })
         .receive("error", resp => { console.log("app.init Unable to join", resp) });

}

function start() {
  let root = document.getElementById('root');  
  if (root) {
    console.log(window.user_id)
    let channel = socket.channel("games:" + window.gameName, {user_id: window.user_id});
    game_init(root, channel, window.user_id);
  }

  if (document.getElementById('index-page')) {
    form_init();

  }
}
// Use jQuery to delay until page loaded.
$(start);

