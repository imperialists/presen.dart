#import('dart:html');
#import('dart:json');

class Controller {
  WebSocket _socket;

  Controller() {
    final Location location = window.location;
    String url = 'ws://${location.host}/control';
    _socket = new WebSocket(url);
  }
}

/**
 * Controller.
 * This should be loaded by the presenter html page.
 *
 * Button/swipe event handler.
 * Sends requests to server by sending HTTP requests.
 */
void main() {
  Controller controller = new Controller();

  document.queryAll('button').forEach((button) {
    button.on.click.add((event) {
      controller._socket.send(button.value);
    });
  });

  int startX, startY, endX, endY;
  final int treshold = 50;

  Element swipe = document.query('#swipe');
  swipe.on.touchStart.add((event) {
    if (event.touches.length == 1) {
      startX = event.touches[0].pageX;
      startY = event.touches[0].pageY;
    }
  });
  swipe.on.touchMove.add((event) {
    event.preventDefault();
    endX = event.touches[0].pageX;
    endY = event.touches[0].pageY;
  });
  swipe.on.touchEnd.add((event) {
    if ((startX - endX) > treshold) {
      send('next');
    }
    if ((endX - startX) > treshold) {
      send('previous');
    }
  });
  swipe.on.touchCancel.add((event) {
    startX = 0; startY = 0;
    endX = 0; endY = 0;
  });
}

void send(String command) {
  final Location location = window.location;
  XMLHttpRequest request = new XMLHttpRequest();
  request.open('GET', '${command}');
  request.send(null);
  //new XMLHttpRequest.get('${location.protocol}/${command}', (req) {
  //});
}
