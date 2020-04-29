
import 'package:stream_data_reader/stream_data_reader.dart';

Stream<List<int>> ss() async* {
	yield '125656563\r\n45656789'.codeUnits;
}

void main() async {
	final reader = ByteBufferReader(StreamReader(ss()));
	final dataReader = DataReader(reader);
	print(await dataReader.readString());
	print(await dataReader.readString());
	print(await dataReader.readString());
}