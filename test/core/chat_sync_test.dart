import 'package:flutter_test/flutter_test.dart';
import 'package:daengle/core/chat_sync.dart';

void main() {
  test('out of order delivery never advances over a gap; duplicates merge', () {
    final timeline = MessageTimeline(joinedSeq: 7);
    timeline.merge([
      {'id': 'nine', 'seq': 9},
    ]);
    expect(timeline.contiguous, 6);
    timeline.merge([
      {'id': 'seven', 'seq': 7},
      {'id': 'eight', 'seq': 8, 'status': 'HIDDEN'},
    ]);
    expect(timeline.contiguous, 9);
    timeline.merge([
      {'id': 'nine', 'seq': 9},
    ]);
    expect(timeline.messages.length, 3);
    expect(timeline.messages.map((m) => m['seq']), [7, 8, 9]);
  });
}
