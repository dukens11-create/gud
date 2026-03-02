import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/message.dart';

void main() {
  group('MessageModel', () {
    final testDate = DateTime(2024, 6, 15, 10, 30);

    test('constructor creates valid MessageModel', () {
      final msg = MessageModel(
        id: 'msg-1',
        senderId: 'user-abc',
        senderRole: 'admin',
        text: 'Hello driver!',
        createdAt: testDate,
      );

      expect(msg.id, 'msg-1');
      expect(msg.senderId, 'user-abc');
      expect(msg.senderRole, 'admin');
      expect(msg.text, 'Hello driver!');
      expect(msg.createdAt, testDate);
    });

    test('constructor defaults createdAt to now when not provided', () {
      final before = DateTime.now();
      final msg = MessageModel(
        id: 'msg-2',
        senderId: 'driver-xyz',
        senderRole: 'driver',
        text: 'On my way',
      );
      final after = DateTime.now();

      expect(msg.createdAt.isAfter(before) || msg.createdAt.isAtSameMomentAs(before), isTrue);
      expect(msg.createdAt.isBefore(after) || msg.createdAt.isAtSameMomentAs(after), isTrue);
    });

    test('toMap serializes MessageModel correctly', () {
      final msg = MessageModel(
        id: 'msg-1',
        senderId: 'user-abc',
        senderRole: 'admin',
        text: 'Hello driver!',
        createdAt: testDate,
      );

      final map = msg.toMap();

      expect(map['senderId'], 'user-abc');
      expect(map['senderRole'], 'admin');
      expect(map['text'], 'Hello driver!');
      expect(map['createdAt'], testDate.toIso8601String());
      // id is not serialized into the map (it comes from the document id)
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap deserializes MessageModel correctly', () {
      final map = {
        'senderId': 'driver-xyz',
        'senderRole': 'driver',
        'text': 'On my way',
        'createdAt': testDate.toIso8601String(),
      };

      final msg = MessageModel.fromMap('msg-42', map);

      expect(msg.id, 'msg-42');
      expect(msg.senderId, 'driver-xyz');
      expect(msg.senderRole, 'driver');
      expect(msg.text, 'On my way');
      expect(msg.createdAt, testDate);
    });

    test('fromMap uses defaults for missing fields', () {
      final msg = MessageModel.fromMap('msg-99', {});

      expect(msg.id, 'msg-99');
      expect(msg.senderId, '');
      expect(msg.senderRole, 'driver');
      expect(msg.text, '');
      // createdAt defaults to DateTime.now() when field is absent
      expect(msg.createdAt, isNotNull);
    });

    test('round-trip serialization preserves all fields', () {
      final original = MessageModel(
        id: 'msg-rt',
        senderId: 'admin-001',
        senderRole: 'admin',
        text: 'Please confirm pickup location.',
        createdAt: testDate,
      );

      final roundTripped = MessageModel.fromMap('msg-rt', original.toMap());

      expect(roundTripped.id, original.id);
      expect(roundTripped.senderId, original.senderId);
      expect(roundTripped.senderRole, original.senderRole);
      expect(roundTripped.text, original.text);
      expect(roundTripped.createdAt, original.createdAt);
    });
  });
}
