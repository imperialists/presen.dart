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
