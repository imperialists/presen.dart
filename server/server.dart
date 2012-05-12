#library('server.dart');

#import('../lib/express.dart/lib/start.dart');
#import('../lib/express.dart/lib/server.dart');

#import('dart:json');
#import('dart:io');

#source('client.dart');

/**
 * Request handler.
 * This is a standalone app listening on websockets.
 *
 * The server that receives HTTP requests from
 * (1) clients    - register clients so we can push slide changes to them
 * (2) controller - receive controller GET requests to move slides
 */
class App extends Server {
  int _state = 1;
  Set _clients;

  /**
   * Send message to all connected clients.
   */
  send(Map message) {
    print('send $message to all clients');
    _clients.forEach((client) {
      client.send(message);
    });
  }

  App() : _clients = new Set() {
    WebSocketHandler handler = new WebSocketHandler();
    server.addRequestHandler((req) => req.path == '/ws', handler.onRequest);

    handler.onOpen = (WebSocketConnection conn) {
      print('client connected');
      Client client = new Client(conn);
      _clients.add(client);

      conn.onMessage = (message) {
        print('message $message');
      };

      conn.onClosed = (int status, String reason) {
        print('client disconnected');
        _clients.remove(client);
      };

      conn.onError = (e) {
        print('client error $e');
      };
    };

    WebSocketHandler controllerHandler = new WebSocketHandler();
    server.addRequestHandler((req) => req.path == '/control',
      controllerHandler.onRequest);

    controllerHandler.onOpen = (WebSocketConnection conn) {
      conn.onMessage = (message) {
        switch (message) {
          case 'next':
            print('socket: move to previous');
            _state++;
            send({ "state": _state });
            break;
          case 'previous':
            print('socket: move to previous');
            _state--;
            send({ 'state': _state });
            break;
          case 'refresh':
            print('socket: refresh');
            send({ 'refresh': true });
            break;
          case 'reset':
            print('socket: reset');
            _state = 1;
            send({ 'state': _state });
            break;
        }
      };
    };

    get('/next', (req, res) {
      print('move to next');
      _state++;
      send({ "state": _state });

      res.send(_state.toString());
    });

    get('/previous', (req, res) {
      print('move to previous');
      _state--;
      send({ 'state': _state });

      res.send(_state.toString());
    });

    get('/refresh', (req, res) {
      print('refresh');
      send({ 'refresh': true });

      res.send(_state.toString());
    });

    get('/reset', (req, res) {
      print('reset');
      _state = 1;
      send({ 'state': _state });

      res.send(_state.toString());
    });

    static = '../client';

    /*get('/controller', (req, res) {
      print('controller');
      res.sendfile('../client/controller.html');
    });

    get('/controller.dart', (req, res) {
      print('controller');
      res.sendfile('../client/controller.dart');
    });

    get('/controller.dart.js', (req, res) {
      print('controller');
      res.sendfile('../client/controller.dart.js');
    });*/
  }
}

void main() {
  new Start.runServer(new App(), '127.0.0.1', 3000);
}
