import 'package:campus_app/main.dart';
import 'package:campus_app/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows missing Mapbox configuration screen', (tester) async {
    await tester.pumpWidget(const MissingMapboxTokenApp());

    expect(
      find.text('Missing Mapbox configuration'),
      findsOneWidget,
    );
  });

  test('ActivityDraft validates the requested user-facing constraints', () {
    final draft = ActivityDraft(
      title: '   ',
      description: null,
      categoryId: '',
      campus: 'edinburg',
      latitude: 91,
      longitude: -181,
      startsAt: DateTime.now(),
      endsAt: DateTime.now().add(const Duration(hours: 1)),
      indoorOutdoor: '',
      building: null,
      floor: null,
      roomOrArea: null,
    );

    final message = draft.validate();
    expect(message, contains('title'));
    expect(message, contains('category'));
    expect(message, contains('coordinate'));
    expect(message, contains('indoor'));
  });
}