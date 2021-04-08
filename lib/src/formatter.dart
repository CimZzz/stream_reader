import 'dart:typed_data';

/// Data formatter
/// A class can help you convert byte data to base type or vice versa.
class DataFormatter {
	DataFormatter._();

	/// Bytes -> Int
	/// Specify byte order, big endian or little endian, default is little endian
	static int byte2Int(Iterable<int> bytes, {bool isBigEndian = false}) {
		var number = 0;
		var mul = 0;
		for(final byte in bytes) {
			if(isBigEndian ?? false) {
				number = (number << 8) | (byte & 0xFF);
			}
			else {
				number |= (byte & 0xFF) << (mul << 3);
			}

			mul ++;
		}

		return number;
	}

	/// Int -> Bytes
	/// Specify byte order, big endian or little endian, default is little endian.
	/// Also can specify byteCount, make sure byte list's length as result
	static Iterable<int> int2Byte(int number, {int byteCount, bool isBigEndian = false}) sync* {
		final byteList = <int>[];
		while(number > 0) {
			byteList.add(number & 0xFF);
			number = number >> 8;
		}


		final listCount = byteList.length;
		final realCount = byteCount ?? listCount;
		if(isBigEndian ?? false) {
			for(var i = realCount - 1 ; i >= 0 ; i --) {
				if(i >= listCount) {
					yield 0;
				}
				else {
					yield byteList[i];
				}
			}
		}
		else {
			for(var i = 0 ; i < realCount ; i ++) {
				if(i >= listCount) {
					yield 0;
				}
				else {
					yield byteList[i];
				}
			}
		}
	}

	/// Bytes -> Float32
	/// Specify byte order, big endian or little endian, default is little endian
	///
	/// * Must have 4 bytes enough, if bytes over 4 bytes, begin from `offset` , default is 0
	static double byte2Float32(List<int> bytes, {int offset = 0, bool isBigEndian = false}) {
		if(bytes == null || bytes.length - offset + 1 < 4) {
			throw Exception('not enough bytes');
		}

		final intData = byte2Int(bytes.sublist(offset, offset + 4), isBigEndian: isBigEndian);
		final data = ByteData(4);
		data.setInt32(0, intData);
		return data.getFloat32(0, isBigEndian ? Endian.big : Endian.little);
	}

	/// Float32 -> Bytes
	/// Specify byte order, big endian or little endian, default is little endian
	static Iterable<int> float32ToByte(double float, {bool isBigEndian = false}) {
		final data = ByteData(4);
		data.setFloat32(0, float);
		return data.buffer.asInt8List();
	}

	/// Bytes -> Float64
	/// Specify byte order, big endian or little endian, default is little endian
	///
	/// * Must have 8 bytes enough, if bytes over 8 bytes, begin from `offset` , default is 0
	static double byte2Float64(List<int> bytes, {int offset = 0, bool isBigEndian = false}) {
		if(bytes == null || bytes.length - offset + 1 < 8) {
			throw Exception('not enough bytes');
		}

		final intData = byte2Int(bytes.sublist(offset, offset + 8), isBigEndian: isBigEndian);
		final data = ByteData(8);
		data.setInt64(0, intData);
		return data.getFloat64(0, isBigEndian ? Endian.big : Endian.little);
	}

	/// Float64 -> Bytes
	/// Specify byte order, big endian or little endian, default is little endian
	static Iterable<int> float64ToByte(double float, {bool isBigEndian = false}) {
		final data = ByteData(8);
		data.setFloat64(0, float);
		return data.buffer.asInt8List();
	}
}