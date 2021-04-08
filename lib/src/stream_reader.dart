import 'dart:async';

/// Use for get stream element by read
/// StreamReader can get one element from stream by [read] method
///
/// Design
///
/// StreamReader has only one constructor and one parameter, call "RawDataStream".
/// While StreamReader creating, subscribe RawDataStream and control it.
///
/// read :
///
/// RawDataStream -> Completer -> Read
///
/// When [read] method call, [_subscription] will call [resume], recv new data to Completer
///  as result [read] return, and then [_subscription] call [pause] again.
///
/// releaseStream:
///
/// If you need data stream instead of read again and again, call [releaseStream].  Subscription
/// will always resume and never pause again until it done. At this time, [read] return `null` forever.
///
class StreamReader<T> {
	/// Constructor
	StreamReader(Stream<T> rawDataStream) {
		_subscription = rawDataStream.listen((event) {
			if (_isRelease) {
				// stream released, add to controller directly
				_releaseController.add(event);
			}
			else {
				// read waiting, add to completer
				if (_readCompleter != null) {
					_readCompleter.complete(event);
					_readCompleter = null;
				}
				else {
					_bufferEvent = event;
					_subscription.pause();
				}
			}
		}, onError: (error, stackTrace) {
			if (_isRelease) {
				// stream released, add error to controller
				_releaseController.addError(error, stackTrace);
			}
			else {
				// read waiting, add error to completer
				_readCompleter.completeError(error, stackTrace);
				_readCompleter = null;
			}
		}, onDone: () {
			destroy();
		});
	}

	/// Stream Subscription
	StreamSubscription<T> _subscription;

	/// Stream Controller
	StreamController<T> _releaseController;

	/// Read Completer
	Completer<T> _readCompleter;

	/// Data Buffer
	T _bufferEvent;

	/// Whether stream is released
	var _isRelease = false;

	/// Whether stream is end
	var _isEnd = false;

	bool get isEnd => _isEnd;

	/// Whether stream is end (include error occur)

	/// Read first data of current data stream
	/// If stream is released or end, return null
	FutureOr<T> read() async {
		if (_isEnd || _isRelease) {
			return null;
		}

		if (_bufferEvent != null) {
			final tempBuffer = _bufferEvent;
			_bufferEvent = null;
			_subscription.resume();
			return tempBuffer;
		}

		_readCompleter ??= Completer();

		return _readCompleter.future;
	}

	/// Release the stream
	/// If stream is released or end, return null
	/// If current is waiting for reading, complete `null` directly
	Stream<T> releaseStream() async* {
		if (_isEnd || _isRelease) {
			return;
		}
		_isRelease = true;
		_subscription.resume();
		if (_readCompleter != null) {
			_readCompleter.complete(null);
			_readCompleter = null;
		}

		if (_bufferEvent != null) {
			final tempBuffer = _bufferEvent;
			_bufferEvent = null;
			yield tempBuffer;
		}

		_releaseController = StreamController();
		yield* _releaseController.stream;
	}

	/// Destroy StreamReader
	void destroy() {
		if (!_isEnd) {
			_isEnd = true;
			_bufferEvent = null;
			if (_isRelease) {
				// stream released, close controller
				_releaseController?.close();
			}
			else if (_readCompleter != null) {
				// if wait reading now, complete `null`
				_readCompleter.complete(null);
				_readCompleter = null;
			}
			_subscription.cancel();
		}
	}
}