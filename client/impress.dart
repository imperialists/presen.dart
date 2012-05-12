#import('dart:html');
#import('dart:json');

class Vector {
  num x = 0, y = 0, z = 0;
}

class State {
  Vector rot;
  Vector pos;
  num scale = 1;

  State() : rot = new Vector(), pos = new Vector();

  String toCSS() =>
      "translate3d(${pos.x}px, ${pos.y}px, ${pos.z}px) rotateX(${rot.x}deg) rotateY(${rot.y}deg) rotateZ(${rot.z}deg) scale(${scale})";
}

class Config {
  num height;
  num width;
  num maxScale;
  num minScale;
  num perspective;
  num transitionDuration;

  num getAttribute(Element root, String a, num def) =>
      (root.attributes[a] == null) ?
        def : Math.parseDouble(root.dataset[a]);

  Config(Element root)
  {
    height = getAttribute(root,"height",768);
    width = getAttribute(root,"width",1024);
    maxScale = getAttribute(root,"maxScale",1);
    minScale = getAttribute(root,"minScale",0);
    perspective = getAttribute(root,"perspective",1000);
    transitionDuration = getAttribute(root,"transitionDuration",1000);
  }
}

class Impress {

  // The top level elements
  Element mImpress;
  Element mCanvas;
  // List of all available steps
  ElementList mSteps;
  // Index of the currently active step
  int mCurrentStep;

  Config mCfg;

  Impress()
  {
    mImpress = document.query('#impress');
    mImpress.innerHTML = '<div id="canvas">'+ mImpress.innerHTML +'</div>';
    mCanvas = document.query('#canvas');
    mSteps = mCanvas.queryAll('.step');
    mCurrentStep = 0;
    mCfg = new Config(mImpress);
  }

  num winScale()
  {
    num hScale = document.window.innerHeight / mCfg.height;
    num wScale = document.window.innerWidth / mCfg.width;
    num scale = Math.min(hScale,wScale);
    scale = Math.min(mCfg.maxScale,scale);
    scale = Math.max(mCfg.minScale,scale);
    return scale;
  }

  String bodyCSS() =>
    "height: 100%; overflow-x: hidden; overflow-y: hidden;";

  String stepCSS(String s) =>
    "position: absolute; -webkit-transform: translate(-50%, -50%) ${s}; -webkit-transform-style: preserve-3d;";

  String canvasCSS(State state) =>
      "position: absolute; -webkit-transform-origin: 0% 0%; -webkit-transition: all 500ms ease-in-out 0ms; -webkit-transform-style: preserve-3d; -webkit-transform: rotateZ(${-state.rot.z}deg) rotateY(${-state.rot.y}deg) rotateX(${-state.rot.x}deg) translate3d(${-state.pos.x}px, ${-state.pos.y}px, ${-state.pos.z}px);";

  String scaleCSS(State state) {
      num windowScale = winScale();
      num targetScale = windowScale / state.scale;
      num perspective = mCfg.perspective / targetScale;
      return "position: absolute; -webkit-transform-origin: 0% 0%; -webkit-transition: all 500ms ease-in-out 250ms; -webkit-transform-style: preserve-3d; top: 50%; left: 50%; -webkit-transform: perspective(${perspective}) scale(${targetScale});";
  }

  void setupPresentation() {
    // Body and html
    document.body.style.cssText = bodyCSS();

    document.head.innerHTML = document.head.innerHTML + '<meta content="width=device-width, minimum-scale=1, maximum-scale=1, user-scalable=no" name="viewport">';

    // Create steps
    mSteps.forEach((Element step) =>
      step.style.cssText = stepCSS(getState(step).toCSS())
    );

    // Create Canvas
    mCanvas.style.cssText = canvasCSS(getState(mSteps[0]));
    mCanvas.elements.first.remove();

    // Scale and perspective
    mImpress.style.cssText = scaleCSS(getState(mSteps[0]));
  } 

  num getAttribute(Element step, String a, num def) =>
    (step.attributes[a] == null) ?
      def : Math.parseDouble(step.attributes[a]);

  State getState(Element step) {
    // We know we want a number, so we can "statically cast"
    num attr(String a, [num def = 0]) => getAttribute(step, a, def);
    State s = new State();
    s.scale = attr('data-scale', 1);
    s.pos.x = attr('data-x');
    s.pos.y = attr('data-y');
    s.pos.z = attr('data-z');
    s.rot.x = attr('data-rotate-x');
    s.rot.y = attr('data-rotate-y');
    // Treat data-rotate as data-rotate-z:
    // Allows using only data-rotate for pure 2D rotation
    s.rot.z = attr('data-rotate-z', attr('data-rotate'));
    return s;
  }

  void goto(int step) {
    // Iterate over attributes of the step jumped to and apply CSS
    mCurrentStep = step % mSteps.length;
    print(canvasCSS(getState(mSteps[mCurrentStep])));
    mCanvas.style.cssText = canvasCSS(getState(mSteps[mCurrentStep]));
    // Scale and perspective
    mImpress.style.cssText = scaleCSS(getState(mSteps[mCurrentStep]));
  }

  void prev() {
    int prev_ = mCurrentStep - 1;
    goto(prev_ >= 0 ? prev_ : mSteps.length-1);
  }

  void next() {
    int next_ = mCurrentStep + 1;
    goto(next_ < mSteps.length ? next_ : 0);
  }
}

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

/**
 * Setup a connection to the presentation server
 * and start listening for commands.
 */
void connectServer(Impress pres) {
  final Location location = window.location;
  String url = 'ws://${location.host}/ws';
  WebSocket _socket = new WebSocket(url);
  Controller controller = new Controller(pres);

  // handle command from server
  _socket.on.message.add((e) {
    Map msg = JSON.parse(e.data);

    if (msg['presenter'] is List) {
      controller.setupControls(msg['presenter']);
    }

    // switch slides
    if (msg['state'] is num) {
      pres.goto(msg['state'] - 1);
    }

    // refresh
    if (msg['refresh']) {
      window.location.reload();
    }

    // new client
    if (msg['client'] != null) {
      controller.generatePresenter(msg['client']);
    }
  });
}

void main() {
  Impress pres = new Impress();
  pres.setupPresentation();
  connectServer(pres);
}
