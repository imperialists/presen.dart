#import('dart:html');
#import('dart:json');

class Controller {
  WebSocket _socket;
  Impress _pres;
  Function _onKey;

  Controller(this._pres) {
    final Location location = window.location;
    String url = 'ws://${location.host}/control';
    _socket = new WebSocket(url);
    _onKey = (Event event) {
      switch (event.keyCode) {
        case 33: // pg up
        case 37: // left
        case 38: // up
          send({ 'command': 'move', 'direction': 'previous' });
          _pres.prev();
          break;
        case 9:  // tab
        case 32: // space
        case 34: // pg down
        case 39: // right
        case 40: // down
          send({ 'command': 'move', 'direction': 'next' });
          _pres.next();
          break;
      }
      event.preventDefault();
    };
  }

  send(data) => _socket.send(JSON.stringify(data));

  /**
   * Generates a status bar a the bottom of a slide.
   */
  generateBottomBar() {
    Element bottomBar = new Element.tag('div');
    bottomBar.id = 'bottombar';
    bottomBar.style.cssText = 'position: fixed; bottom: 10px; left: 10px; pointer-events: auto;';
    document.body.nodes.add(bottomBar);
  }

  /**
   * Generate presenter button on the slide.
   */
  generatePresenter(id) {
    Element bottomBar = document.query('#bottombar');

    Element presentBtn = new Element.tag('button');
    presentBtn.id = id.toString();
    presentBtn.text = id.toString();
    presentBtn.on.click.add((e) {
      send({ 'command': 'switch', 'presenter': id });
      unsetupControls();
    });

    bottomBar.nodes.add(presentBtn);
  }

  setupControls(clients) {
    document.on.keyUp.add(_onKey);

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
        send({ 'command': 'move', 'direction': 'previous' });
        _pres.prev();
      }
      if ((endX - startX) > treshold) {
        send({ 'command': 'move', 'direction': 'next' });
        _pres.next();
      }
    });
    swipe.on.touchCancel.add((event) {
      startX = 0; startY = 0;
      endX = 0; endY = 0;
    });

    generateBottomBar();
    clients.forEach((client) {
      generatePresenter(client);
    });
  }

  unsetupControls() {
    document.on.keyUp.remove(_onKey);
    document.query('#bottombar').nodes.clear();
  }
}
