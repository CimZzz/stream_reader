import 'dart:async';

import 'stream_reader.dart';

abstract class ByteBufferReader {
	factory ByteBufferReader(StreamReader<List<int>> streamReader) {
		return _ByteListBufferReader(streamReader);
	}

	ByteBufferReader._();

	FutureOr<List<int>> readBytes({int length});

	FutureOr<int> readOneByte();

	Stream<List<int>> releaseStream();

	FutureOr<List<int>> readUntil({List<List<int>> terminators, bool endTerminate = false});

	bool isEnd();

	void destroy();
}

/// Byte list buffer reader
class _ByteListBufferReader extends ByteBufferReader {
	_ByteListBufferReader(StreamReader<List<int>> streamReader):
			_reader = streamReader,
			super._();

	/// StreamReader
	/// All [read] method base on this reader.
	final StreamReader<List<int>> _reader;

	/// Byte list buffer
	/// Use to store unused-up byte data
	List<int> _buffer;

	/// Read sync locked.
	/// At one time, only allow single one to read, other will return null
	var isReading = false;

	/// Stream released flag
	var isRelease = false;

	/// Prevent more time call [read] method at moment.
	FutureOr<T> _readLimit<T>(FutureOr<T> Function() runnable) async {
		if(isRelease) {
			throw Exception('Reader is released...');
		}
		if(isReading) {
			throw Exception('Cannot read at the same time');
		}
		final result = await runnable();
		isReading = false;
		return result;
	}

	/// Read byte data list from StreamReader
	/// Unlimited read size, base on raw data stream read byte count at once.
	Future<List<int>> _readFromReader() {
		return _reader.read();
	}

	/// Read byte data until [predict] return true
	FutureOr<List<int>> _readUntil(bool Function(int) predict, bool endTerminate) async {
		// visit buffer first
		int count;
		if(_buffer != null) {
			count = _buffer.length;
			for(var i = 0 ; i < count ; i ++) {
				if(predict(_buffer[i])) {
					// 中断
					if(i == count - 1) {
						final tempList = _buffer;
						_buffer = null;
						return tempList;
					}
					else {
						final tempList = _buffer.sublist(0, i + 1);
						_buffer = _buffer.sublist(i + 1);
						return tempList;
					}
				}
			}
		}

		// buffer not enough, visit more data
		while(true) {
			final newBuffer = await _readFromReader();
			if(newBuffer == null) {
				if(endTerminate) {
					final tempList = _buffer;
					_buffer = null;
					return tempList;
				}
				throw Exception('not enough bytes');
			}
			count = newBuffer.length;
			for(var i = 0 ; i < count ; i ++) {
				if(predict(newBuffer[i])) {
					// 中断
					if(i == count - 1) {

						final tempList = _buffer != null ? _buffer + newBuffer : newBuffer;
						_buffer = null;
						return tempList;
					}
					else {
						final tempList = _buffer != null ? _buffer + newBuffer.sublist(0, i + 1) : newBuffer.sublist(0, i + 1);
						_buffer = newBuffer.sublist(i + 1);
						return tempList;
					}
				}
			}
			if(_buffer == null) {
				_buffer = newBuffer;
			}
			else {
				_buffer += newBuffer;
			}
		}
	}

	/// Read specified length byte list
	@override
	FutureOr<List<int>> readBytes({int length}) {
		return _readLimit<List<int>>(() async {
			if(_buffer == null) {
				_buffer = await _readFromReader();
				if(_buffer == null) {
					throw Exception('not enough bytes');
				}
			}
			while(_buffer.length < length) {
				final readByteList = await _readFromReader();
				if(readByteList == null) {
					throw Exception('not enough bytes');
				}
				_buffer += readByteList;
			}
			List<int> tempList;
			if(_buffer.length == length) {
				tempList = _buffer;
				_buffer = null;
			}
			else {
				tempList = _buffer.sublist(0, length);
				_buffer = _buffer.sublist(length);
			}

			return tempList;
		});
	}

	/// Read one byte
	@override
	FutureOr<int> readOneByte() {
		return _readLimit<int>(() async {
			final byteList = await readBytes(length: 1);
			return byteList[0];
		});
	}

	/// Read until terminator matched
	@override
	FutureOr<List<int>> readUntil({List<List<int>> terminators, bool endTerminate = false}) {
		if(terminators == null || terminators.isEmpty || terminators.firstWhere((element) => element.isEmpty, orElse: () => null) != null) {
			return null;
		}

		final count = terminators.length;

		final idxList = List.filled(count, 0);

		return _readLimit(() => _readUntil((byte) {
			for(var i = 0 ; i < count ; i ++) {
				final idx = idxList[i];
				final terminatorList = terminators[i];
				if(byte == terminatorList[idx]) {
					if(idx == terminatorList.length - 1) {
						// completed, stop finding...
						return true;
					}

					idxList[i] += 1;
				}
				else {
					idxList[i] = 0;
				}
			}
			return false;
		}, endTerminate));
	}

	/// Release data stream
	@override
	Stream<List<int>> releaseStream() {
		return _readLimit(() async* {
			isRelease = true;
			if(_buffer != null) {
				yield _buffer;
			}
			yield* _reader.releaseStream();
		});
	}

	/// Whether the read is down
	@override
	bool isEnd() => _reader.isEnd;

	/// Destroy reader
	@override
	void destroy() {
		isRelease = true;
		_buffer = null;
		_reader.destroy();
	}
}