import 'package:flutter_test/flutter_test.dart';
import 'package:enochwinplan/models/study_models.dart';

void main() {
  test('favorite persona can be serialized and restored', () {
    final persona = FavoritePersona(
      id: 'fav-1',
      date: '2026-06-30',
      personaId: 'phase-line-captain',
      title: '相位线队长',
      note: '适合把今天拆成清晰步骤',
    );

    final restored = FavoritePersona.fromJson(persona.toJson());

    expect(restored.id, 'fav-1');
    expect(restored.date, '2026-06-30');
    expect(restored.personaId, 'phase-line-captain');
    expect(restored.title, '相位线队长');
    expect(restored.note, '适合把今天拆成清晰步骤');
  });
}
