import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_horror_podcast/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('formatDuration formats mm:ss and hh:mm:ss correctly', () {
      expect(Formatters.formatDuration(0), '00:00');
      expect(Formatters.formatDuration(65), '01:05');
      expect(Formatters.formatDuration(3665), '1:01:05');
      expect(Formatters.formatDuration(-10), '00:00');
    });

    test('formatFileSize formats B, KB, MB, GB accurately', () {
      expect(Formatters.formatFileSize(0), '0 B');
      expect(Formatters.formatFileSize(1024), '1.0 KB');
      expect(Formatters.formatFileSize(15728640), '15.0 MB');
      expect(Formatters.formatFileSize(1073741824), '1.0 GB');
    });
  });
}
