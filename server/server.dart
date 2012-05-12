#library("presen.dart");

#import("../lib/start/lib/start.dart");
#import("../lib/start/lib/server.dart");

#import("dart:json");
#import("dart:io");

class Client implements Hashable {
  Client(this._connection) {
    _hashCode = _nextHashCode;
    _nextHashCode = (_nextHashCode + 1) & 0xFFFFFFF;
  }

  send(Object message) {
    _connection.send(JSON.stringify(message));
  }

  int hashCode() => _hashCode;

  // Client web socket connection
  WebSocketConnection _connection;

  // Hash code for the client
  int _hashCode;
  static int _nextHashCode = 0;
}

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

    get('/controller', (req, res) {
      print('controller');
      res.sendfile('controller.html');
    });
  }
}

void main() {
  new Start.runServer(new App(), '127.0.0.1', 3000);
}
