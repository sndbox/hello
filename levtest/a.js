"use strict";

var onflight = false;
var input = document.querySelector('#input');
var output = document.querySelector('#output');
var ws = new WebSocket('ws://localhost:8084')
ws.onopen = function() { console.log('onopen'); };
ws.onclose = function() { console.log('onclose'); };
ws.onerror = function() { console.log('onerror'); };
ws.onmessage = function(msg) {
  output.innerHTML = msg.data;
  onflight = false;
};

input.addEventListener('keyup', function(e) {
  if (onflight == false) {
    onflight = true;
    ws.send(input.value);
  } else {
    console.log('waiting...');
  }
});
