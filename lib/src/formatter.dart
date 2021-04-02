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
}