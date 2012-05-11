/**
 * Client.
 * This should be loaded by the client html page.
 *
 * Connect to server via websocket and handle push messages from server.
 */

#import('dart:html');
#import('dart:io');
#import('dart:json');

class PresendartClient {

  bool _sync;
  Socket _socket;

  void connect() {
    String host = document.query('#host_id').attributes['value'];
    int port = Math.parseInt(document.query('#port_id').attributes['value']);
    Element canvas = document.query('#canvas');
    canvas.innerHTML = 'Connecting to $host:$port.. (Slide goes here)';

    _socket = new Socket(host, port);

    _socket.onData = () {
      Map data = JSON.parse(_socket.inputStream.read().toString());
      updateSlides(data);
    };
  }

  void updateSlides(Map data) {
  }

}

void main()
{
  PresendartClient pc = new PresendartClient();
  document.query('#startbutton').on.click.add(
    (e) { pc.connect(); }
  );
}
