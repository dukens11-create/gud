import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/pod.dart';

void main() {
  group('POD', () {
    final testDate = DateTime(2024, 1, 1, 12, 0, 0);
    
    test('constructor creates valid POD', () {
      final pod = POD(
        id: 'pod-123',
        loadId: 'load-456',
        imageUrl: 'https://example.com/image.jpg',
        uploadedAt: testDate,
        notes: 'Delivered to front desk',
        uploadedBy: 'driver-789',
      );

      expect(pod.id, 'pod-123');
      expect(pod.loadId, 'load-456');
      expect(pod.imageUrl, 'https://example.com/image.jpg');
      expect(pod.uploadedAt, testDate);
      expect(pod.notes, 'Delivered to front desk');
      expect(pod.uploadedBy, 'driver-789');
    });

    test('toMap serializes POD correctly', () {
      final pod = POD(
        id: 'pod-123',
        loadId: 'load-456',
        imageUrl: 'https://example.com/image.jpg',
        uploadedAt: testDate,
        notes: 'Delivered to front desk',
        uploadedBy: 'driver-789',
      );

      final map = pod.toMap();

      expect(map['loadId'], 'load-456');
      expect(map['imageUrl'], 'https://example.com/image.jpg');
      expect(map['uploadedAt'], testDate.toIso8601String());
      expect(map['notes'], 'Delivered to front desk');
      expect(map['uploadedBy'], 'driver-789');
      expect(map.containsKey('id'), false); // id is not serialized
    });

    test('fromMap deserializes POD correctly', () {
      final map = {
        'loadId': 'load-456',
        'imageUrl': 'https://example.com/image.jpg',
        'uploadedAt': testDate.toIso8601String(),
        'notes': 'Delivered to front desk',
        'uploadedBy': 'driver-789',
      };

      final pod = POD.fromMap('pod-123', map);

      expect(pod.id, 'pod-123');
      expect(pod.loadId, 'load-456');
      expect(pod.imageUrl, 'https://example.com/image.jpg');
      expect(pod.uploadedAt, testDate);
      expect(pod.notes, 'Delivered to front desk');
      expect(pod.uploadedBy, 'driver-789');
    });

    test('fromMap handles missing optional fields with defaults', () {
      final map = {
        'uploadedAt': testDate.toIso8601String(),
      };

      final pod = POD.fromMap('pod-123', map);

      expect(pod.loadId, '');
      expect(pod.imageUrl, '');
      expect(pod.uploadedAt, testDate);
      expect(pod.notes, '');
      expect(pod.uploadedBy, '');
    });

    test('serialization roundtrip maintains data integrity', () {
      final original = POD(
        id: 'pod-123',
        loadId: 'load-456',
        imageUrl: 'https://example.com/image.jpg',
        uploadedAt: testDate,
        notes: 'Delivered successfully',
        uploadedBy: 'driver-789',
      );

      final map = original.toMap();
      final deserialized = POD.fromMap(original.id, map);

      expect(deserialized.id, original.id);
      expect(deserialized.loadId, original.loadId);
      expect(deserialized.imageUrl, original.imageUrl);
      expect(deserialized.uploadedAt, original.uploadedAt);
      expect(deserialized.notes, original.notes);
      expect(deserialized.uploadedBy, original.uploadedBy);
    });

    test('handles various image URL formats', () {
      final imageUrls = [
        'https://storage.googleapis.com/bucket/file.jpg',
        'https://example.com/path/to/image.png',
        'file:///local/path/image.jpg',
        '',
      ];

      for (final url in imageUrls) {
        final pod = POD(
          id: 'pod-test',
          loadId: 'load-test',
          imageUrl: url,
          uploadedAt: testDate,
          notes: 'Test',
          uploadedBy: 'driver-test',
        );

        expect(pod.imageUrl, url);
        
        final map = pod.toMap();
        expect(map['imageUrl'], url);
        
        final deserialized = POD.fromMap(pod.id, map);
        expect(deserialized.imageUrl, url);
      }
    });

    test('handles empty notes correctly', () {
      final pod = POD(
        id: 'pod-123',
        loadId: 'load-456',
        imageUrl: 'https://example.com/image.jpg',
        uploadedAt: testDate,
        notes: '',
        uploadedBy: 'driver-789',
      );

      expect(pod.notes, '');
      
      final map = pod.toMap();
      expect(map['notes'], '');
      
      final deserialized = POD.fromMap(pod.id, map);
      expect(deserialized.notes, '');
    });

    test('handles long notes correctly', () {
      final longNotes = 'This is a very long note ' * 50;
      
      final pod = POD(
        id: 'pod-123',
        loadId: 'load-456',
        imageUrl: 'https://example.com/image.jpg',
        uploadedAt: testDate,
        notes: longNotes,
        uploadedBy: 'driver-789',
      );

      expect(pod.notes, longNotes);
      expect(pod.notes.length, greaterThan(100));
    });
  });
}
