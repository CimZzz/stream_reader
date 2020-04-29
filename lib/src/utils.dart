import 'dart:async';

import '../stream_data_reader.dart';
import 'data_reader.dart';

typedef ByteStreamTransformer<T> = FutureOr<T> Function(DataReader reader);

/// Byte stream builder
/// Use [DataReader] to handle byte data, and transform to specified type data
/// For example:
///
/// Stream<List<int>> testStream() async* {
///     yield [0x00, 0x00, 0x01, 0x00];
///     yield [0x00, 0x00, 0x00, 0x01];
/// }
///
/// void main() {
///     transformByteStream(testStream(), (dataReader) {
///         return dataReader.readInt();
///     }).listen(print);
/// }
///
/// Output:
///
/// 256
/// 1
///
Stream<T> transformByteStream<T>(Stream<List<int>> rawStream, ByteStreamTransformer<T> builder) async* {
	final reader = DataReader(ByteBufferReader(StreamReader(rawStream)));
	while(!reader.isEnd) {
		final transformedData = await builder(reader);
		yield transformedData;
	}
}



typedef StreamTransformer<T, E> = FutureOr<E> Function(StreamReader<T> reader);

/// Byte stream builder
/// Use [DataReader] to handle byte data, and transform to specified type data
/// For example:
///
/// Stream<int> testStream() async* {
///     yield 0;
///     yield 0;
///     yield 1;
///     yield 0;
/// }
///
/// void main() {
///     transformStream(testStream(), (streamReader) {
///         return streamReader.read();
///     }).listen(print);
/// }
///
/// Output:
///
/// 0
/// 0
/// 1
/// 0
///
Stream<E> transformStream<T, E>(Stream<T> rawStream, StreamTransformer<T, E> builder) async* {
	final reader = StreamReader<T>(rawStream);
	while(!reader.isEnd) {
		final transformedData = await builder(reader);
		yield transformedData;
	}
}
