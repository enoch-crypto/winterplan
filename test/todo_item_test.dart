import 'package:flutter_test/flutter_test.dart';
import 'package:enochwinplan/models/study_models.dart';

void main() {
  test('todo item can be serialized and restored', () {
    final item = TodoItem(
      id: 'todo-1',
      content: '整理明天任务',
      isDone: true,
      createdAt: '2026-06-30T10:00:00.000',
    );

    final restored = TodoItem.fromJson(item.toJson());

    expect(restored.id, 'todo-1');
    expect(restored.content, '整理明天任务');
    expect(restored.isDone, isTrue);
    expect(restored.createdAt, '2026-06-30T10:00:00.000');
  });
}
