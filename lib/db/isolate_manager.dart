import 'dart:async';
import 'dart:io';
import 'dart:isolate';

/// Creates a N isolates, where N is the number of cores.
/// Is a simple scheduler, that decides where the computation goes.
class IsolateManager<R, T> {
  static final Finalizer<List<_IsolateInstance>> _finalizer = Finalizer(_dispose);

  final List<_IsolateInstance> _isolates = [];

  FutureOr<R> Function(T) workFn;
  final int isolateNumber;

  IsolateManager(this.workFn, [int? isolateNumber])
      : isolateNumber = isolateNumber ?? Platform.numberOfProcessors;

  Future<void> init() async {
    assert(_isolates.isEmpty);
    int i = 0;
    while (i < isolateNumber) {
      _isolates.add(await _initIsolate("$i"));
      i++;
    }

    _finalizer.attach(this, _isolates);
  }

  Future<_IsolateInstance> _initIsolate(String? debugName) async {
    final thisReceiver = ReceivePort();
    final isolateSender = thisReceiver.sendPort;
    final stream = thisReceiver.asBroadcastStream();

    final isolate = await Isolate.spawn<(SendPort, FutureOr<R> Function(T))>(
      _isolateEntry,
      (isolateSender, workFn),
      debugName: debugName,
    );
    final thisSendport = (await stream.first) as SendPort;

    return _IsolateInstance(isolate, stream, thisSendport, thisReceiver);
  }

  static void _isolateEntry<R, T>((SendPort isolateSender, FutureOr<R> Function(T) workFn) message) {
    final (sender, fn) = message;
    final receiver = ReceivePort();
    sender.send(receiver.sendPort);

    receiver.listen((message) async {
      final param = message as _Request<T>;
      final result = await fn(param.data);
      sender.send(_Response(param, result));
    });
  }

  static void _dispose(List<_IsolateInstance> isolates) {
    for (final isolate in isolates) {
      isolate.close();
    }
    isolates.clear();
  }

  Future<R> run(T param) async {
    assert(_isolates.isNotEmpty);

    /// The simplest scheduler. Always choose the isolate with less on going requests
    _IsolateInstance selected = _isolates[0];
    for (final instance in _isolates) {
      if (selected.onGoingRequests > instance.onGoingRequests) {
        selected = instance;
      }
    }

    final result = await selected.send<R, T>(_Request(param));
    return result.data;
  }
}

class _IsolateInstance {
  final Isolate isolate;
  final Stream<dynamic> reciever;
  final ReceivePort port;
  final SendPort sender;

  _IsolateInstance(this.isolate, this.reciever, this.sender, this.port) {
    reciever.listen((event) {
      final message = event as _Response;
      _requests[message.id]?.complete(message);
    });
  }

  final Map<int, Completer<_Response>> _requests = {};
  int get onGoingRequests => _requests.length;

  void close() {
    port.close();
    isolate.kill(priority: Isolate.immediate);
  }

  Future<_Response<R>> send<R, T>(_Request<T> request) async {
    final completer = Completer<_Response<R>>();
    _requests[request.id] = completer;
    sender.send(request);
    final result = await completer.future;
    _requests.remove(request.id);
    return result;
  }
}

/// especific for 64bit backed integers
const int maxInteger = 0x7FFFFFFFFFFFFFFF;
const int minInteger = -0x8000000000000000;

class _Request<T> {
  final int id;
  final T data;
  _Request(this.data) : id = createID();

  static int _idRequest = minInteger;
  static int createID() {
    if (_idRequest == maxInteger) {
      _idRequest = minInteger;
    } else {
      _idRequest += 1;
    }
    return _idRequest;
  }
}

class _Response<T> {
  final int id;
  final T data;
  _Response(_Request request, this.data) : id = request.id;
}
