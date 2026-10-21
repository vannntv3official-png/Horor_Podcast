import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_horror_podcast/shared/models/category_model.dart';
import 'package:khmer_horror_podcast/shared/models/download_item_model.dart';
import 'package:khmer_horror_podcast/shared/models/episode_model.dart';
import 'package:khmer_horror_podcast/shared/models/story_model.dart';

void main() {
  group('StoryModel Tests', () {
    test('parses json correctly with joined category', () {
      final json = {
        'id': 'story-123',
        'title': 'វិញ្ញាណវិលវល់',
        'slug': 'ghost-battambang',
        'description': 'រឿងខ្មោចពិត',
        'cover_path': 'story-covers/test.jpg',
        'category_id': 'cat-1',
        'categories': {'name': 'រឿងខ្មោចព្រាយបិសាច'},
        'narrator_name': 'សុខ រ៉ាវី',
        'status': 'published',
        'is_featured': true,
        'published_at': '2026-10-20T10:00:00Z',
      };

      final story = StoryModel.fromJson(json);

      expect(story.id, 'story-123');
      expect(story.title, 'វិញ្ញាណវិលវល់');
      expect(story.categoryName, 'រឿងខ្មោចព្រាយបិសាច');
      expect(story.isFeatured, true);
      expect(story.getCoverUrl('https://xyz.supabase.co'), contains('story-covers/test.jpg'));
    });
  });

  group('EpisodeModel Tests', () {
    test('parses episode and generates audio storage url', () {
      final json = {
        'id': 'ep-1',
        'story_id': 'story-123',
        'title': 'ភាគ ១៖ ទ្វារឈើ',
        'episode_number': 1,
        'audio_path': 'podcast-audio/ep1.mp3',
        'audio_size_bytes': 15728640,
        'duration_seconds': 1420,
        'status': 'published',
        'allow_download': true,
      };

      final ep = EpisodeModel.fromJson(json);

      expect(ep.id, 'ep-1');
      expect(ep.episodeNumber, 1);
      expect(ep.durationSeconds, 1420);
      expect(ep.allowDownload, true);
      expect(ep.getAudioUrl('https://xyz.supabase.co'), 'https://xyz.supabase.co/storage/v1/object/public/podcast-audio/ep1.mp3');
    });
  });

  group('CategoryModel Tests', () {
    test('parses category fields and icon correctly', () {
      final json = {
        'id': 'cat-1',
        'name': 'រឿងព្រេងបុរាណ',
        'slug': 'ancient-folklore',
        'icon_name': 'book-open',
        'sort_order': 2,
        'is_active': true,
      };

      final cat = CategoryModel.fromJson(json);

      expect(cat.name, 'រឿងព្រេងបុរាណ');
      expect(cat.slug, 'ancient-folklore');
      expect(cat.sortOrder, 2);
    });
  });

  group('DownloadItemModel Tests', () {
    test('serializes and deserializes accurately with copyWith', () {
      final item = DownloadItemModel(
        episodeId: 'ep-1',
        storyId: 'story-1',
        storyTitle: 'រឿងខ្មោច',
        episodeTitle: 'ភាគ ១',
        episodeNumber: 1,
        localFilePath: '/data/user/0/app/audio/ep1.mp3',
        fileSizeBytes: 12000000,
        durationSeconds: 900,
        downloadedAt: DateTime.parse('2026-10-22T00:00:00Z'),
      );

      final json = item.toJson();
      final revived = DownloadItemModel.fromJson(json);

      expect(revived.episodeId, 'ep-1');
      expect(revived.status, DownloadStatus.completed);
      expect(revived.fileSizeBytes, 12000000);

      final updated = revived.copyWith(progress: 0.5, status: DownloadStatus.downloading);
      expect(updated.progress, 0.5);
      expect(updated.status, DownloadStatus.downloading);
    });
  });
}
