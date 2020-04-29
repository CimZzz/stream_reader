import 'dart:async';
import 'dart:convert';
import 'byte_buffer_reader.dart';

abstract class BaseDataReader {
	BaseDataReader(this._reader);

	final ByteBufferReader _reader;

	/// Read bytes from byte buffer reader
	FutureOr<List<int>> readBytes({int length}) => _reader.readBytes(length: length);

	/// Read one byte from byte buffer reader
	FutureOr<int> readOneByte() => _reader.readOneByte();

	/// Read until terminators match
	FutureOr<List<int>> readUntil({List<List<int>> terminators, bool needRemoveTerminator = false, bool endTerminate = false}) => _reader.readUntil(
		terminators: terminators,
		needRemoveTerminator: needRemoveTerminator,
		endTerminate: endTerminate,
	);

	/// Release byte buffer reader stream
	Stream<List<int>> releaseStream() => _reader.releaseStream();


	/// Whether the read is down
	bool isEnd() => _reader.isEnd();

	/// Destroy reader
	void destroy() {
		_reader.destroy();
	}
}

/// Normal Data Reader
class DataReader extends BaseDataReader {
    DataReader(ByteBufferReader reader) : super(reader);

	/// Read four-bytes int
    /// - [bigEndian] : Big endian
	FutureOr<int> readInt({bool bigEndian = true,}) async {
		final byteList = await readBytes(length: 4);
		bigEndian ??= true;
		if(bigEndian) {
			return ((byteList[0] & 0xFF) << 24)
			| ((byteList[1] & 0xFF) << 16)
			| ((byteList[2] & 0xFF) << 8)
			| ((byteList[3] & 0xFF));
		}
		else {
			return ((byteList[3] & 0xFF) << 24)
			| ((byteList[2] & 0xFF) << 16)
			| ((byteList[1] & 0xFF) << 8)
			| ((byteList[0] & 0xFF));
		}
	}

	/// Read one line string
	FutureOr<String> readString({bool keepLineBreak = true}) async {
		final byteList = await _reader.readUntil(terminators: ['\n'.codeUnits], needRemoveTerminator: !keepLineBreak,endTerminate: true);
		if(byteList == null) {
			return null;
		}
		return utf8.decode(byteList, allowMalformed: true);
	}
}