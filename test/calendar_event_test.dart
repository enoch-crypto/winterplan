import 'package:flutter_test/flutter_test.dart';
import 'package:enochwinplan/models/study_models.dart';

void main() {
  test('calendar event can be serialized and restored', () {
    final event = CalendarEvent(
      id: 'event-1',
      date: '2026-06-30',
      title: '体检',
      note: '上午 9 点',
    );

    final restored = CalendarEvent.fromJson(event.toJson());

    expect(restored.id, 'event-1');
    expect(restored.date, '2026-06-30');
    expect(restored.title, '体检');
    expect(restored.note, '上午 9 点');
  });
}
