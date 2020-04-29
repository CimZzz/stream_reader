import 'package:stream_reader/stream_reader.dart';

Stream<List<int>> ss() async* {
	yield '125656563\r\n45656789'.codeUnits;
}

void main() async {
	final reader = ByteBufferReader.byteListReader(StreamReader(ss()));
	final dataReader = DataReader(reader);
	print(await dataReader.readString());
}