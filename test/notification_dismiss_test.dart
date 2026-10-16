import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wero/services/notification_dismiss_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationDismissService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('dismiss, getDismissedIds, and restore work correctly', () async {
      const service = NotificationDismissService();

      var dismissed = await service.getDismissedIds();
      expect(dismissed, isEmpty);

      await service.dismiss('event-1');
      await service.dismiss('event-2');

      dismissed = await service.getDismissedIds();
      expect(dismissed, containsAll({'event-1', 'event-2'}));

      await service.restore('event-1');
      dismissed = await service.getDismissedIds();
      expect(dismissed, contains('event-2'));
      expect(dismissed, isNot(contains('event-1')));
    });

    test('dismissAll marks all specified IDs as dismissed', () async {
      const service = NotificationDismissService();

      await service.dismissAll(['evt-a', 'evt-b', 'evt-c']);
      final dismissed = await service.getDismissedIds();
      expect(dismissed.length, equals(3));
      expect(dismissed, containsAll({'evt-a', 'evt-b', 'evt-c'}));
    });
  });
}
