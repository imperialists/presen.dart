/**
 * Client.
 * This should be loaded by the client html page.
 *
 * Connect to server via websocket and handle push messages from server.
 */

#import('dart:html');
#import('dart:json');

class PresendartClient {

  bool _sync;
  WebSocket _ws;

  PresendartClient() {
    _sync = false;
  }

  void connect() {
    String host = document.query('#host_id').value;
    String path = document.query('#path_id').value;
    String url  = 'ws://$host/$path';
    Element canvas = document.query('#canvas');
    canvas.innerHTML = 'Connecting to $url.. (Slide goes here)';

    _ws = new WebSocket(url);
    // TODO: Check that _ws is valid
    _ws.on.message.add(
      (e) {
        Map msg = JSON.parse(e.data);
        updateSlides(msg);
      }
    );

  }

  void updateSlides(Map msg) {
    if (_sync && msg['state']) {
      window.location.hash = msg['state'];
    }

    if (msg['refresh']) {
      window.location.reload();
    }
  }

}

void main()
{
  PresendartClient pc = new PresendartClient();
  document.query('#startbutton').on.click.add(
    (e) {
      pc.connect();
    });
}
