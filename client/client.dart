/**
 * Client.
 * This should be loaded by the client html page.
 *
 * Connect to server via websocket and handle push messages from server.
 */

#import('dart:html');
#import('dart:json');

class PresendartClient {
  WebSocket _ws;

  void connect() {
    String url  = 'ws://127.0.0.1:3000/ws';
    Element canvas = document.query('#canvas');
    canvas.innerHTML = 'Connecting to $url.. (Slide goes here)';

    _ws = new WebSocket(url);
    // TODO: Check that _ws is valid
    _ws.on.message.add((e) {
      Map msg = JSON.parse(e.data);
      updateSlides(msg);
    });

  }

  void updateSlides(Map msg) {
    if (msg['state']) {
      window.location.hash = msg['state'];
    }

    if (msg['refresh']) {
      window.location.reload();
    }
  }

}

void main() {
  PresendartClient pc = new PresendartClient();
  pc.connect();
}
