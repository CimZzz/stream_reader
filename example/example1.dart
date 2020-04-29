import 'package:stream_data_reader/stream_data_reader.dart';

Stream<List<int>> testStream() async* {
	yield [0x00, 0x00, 0x01, 0x00];
	yield [0x00, 0x00, 0x00, 0x01];
}

void main() async {
	final dataReader = DataReader(ByteBufferReader(StreamReader(testStream())));
	print(await dataReader.readInt());
	transformStream(transformByteStream(dataReader.releaseStream(), (reader) {
		return reader.readOneByte();
	}), (reader) {
		return reader.read();
	}).listen(print);
}