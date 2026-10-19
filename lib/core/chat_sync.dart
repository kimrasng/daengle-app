import 'api.dart';

/// The cursor advances only over a contiguous sequence, including hidden tombstones.
class MessageTimeline {
  int contiguous;
  final Map<int, Json> _messages = {};
  MessageTimeline({required int joinedSeq}) : contiguous = joinedSeq - 1;
  List<Json> get messages =>
      _messages.values.toList()
        ..sort((a, b) => (a['seq'] as num).compareTo(b['seq'] as num));
  void merge(List<Json> messages) {
    for (final message in messages) {
      final seq = (message['seq'] as num).toInt();
      _messages[seq] = message;
    }
    while (_messages.containsKey(contiguous + 1)) {
      contiguous++;
    }
  }
}
