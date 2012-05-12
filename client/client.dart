/**
 * Client.
 * This should be loaded by the client html page.
 *
 * Connect to server via websocket and handle push messages from server.
 */

#import('dart:html');
#import('dart:json');

class Client {
  WebSocket _socket;

  void connect() {
    final Location location = window.location;
    String url = 'ws://${location.host}/ws';
    //Element canvas = document.query('#canvas');
    //canvas.innerHTML = 'Connecting to $url.. (Slide goes here)';

    _socket = new WebSocket(url);
    // TODO: Check that _ws is valid
    _socket.on.message.add((e) {
      print('1');
      Map msg = JSON.parse(e.data);
      print('2');
      updateSlides(msg);
    });
  }

  void updateSlides(Map msg) {
    print('3');
    if (msg['state'] is num) {
      print('4');
      print(msg['state']);
      if (window.location.toString().contains(new RegExp('#'))) {
        window.location.assign(window.location.toString().replace(new RegExp('#[0-9]*'), '#${msg['state']}'));
      } else {
        window.location.assign('${window.location}#${msg['state']}');
      }
      // window.location.hash = msg['state'];
    }

    if (msg['refresh']) {
      window.location.reload();
    }
  }

}

void main() {
  Client client = new Client();
  client.connect();
}
