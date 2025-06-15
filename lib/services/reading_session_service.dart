import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingSessionService {
  static final _supabase = Supabase.instance.client;

  static Future<void> saveSession({
    required dynamic bookId,
    required int duration,
    required DateTime completedAt,
  }) async {
    try {
      print('=== SAVING READING SESSION ===');
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No authenticated user found');
        throw Exception('User not authenticated');
      }
      print('✅ User ID: $userId');

      // Convert bookId to int if it's a String
      int finalBookId;
      if (bookId is String) {
        finalBookId = int.parse(bookId);
      } else if (bookId is int) {
        finalBookId = bookId;
      } else {
        throw Exception('Invalid bookId type: ${bookId.runtimeType}');
      }
      print('✅ Book ID: $finalBookId');
      print('✅ Duration: $duration seconds');
      print('✅ Completed at: $completedAt');

      final sessionData = {
        'user_id': userId,
        'book_id': finalBookId,
        'duration_seconds': duration,
        'completed_at': completedAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };
      
      print('📤 Inserting session data: $sessionData');

      final response = await _supabase.from('reading_sessions').insert(sessionData);
      
      print('✅ Reading session saved successfully');
      print('📊 Response: $response');
    } catch (e) {
      print('❌ Error saving reading session: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserSessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('reading_sessions')
          .select('''
            *,
            books (
              title,
              author,
              cover_image_url
            )
          ''')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reading sessions: $e');
      return [];
    }
  }

  static Future<Map<String, int>> getReadingStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'totalSessions': 0, 'totalMinutes': 0};

      final response = await _supabase
          .from('reading_sessions')
          .select('duration_seconds')
          .eq('user_id', userId);

      final sessions = List<Map<String, dynamic>>.from(response);
      final totalSessions = sessions.length;
      final totalSeconds = sessions.fold<int>(
        0,
        (sum, session) => sum + (session['duration_seconds'] as int? ?? 0),
      );

      return {
        'totalSessions': totalSessions,
        'totalMinutes': (totalSeconds / 60).round(),
      };
    } catch (e) {
      print('Error fetching reading stats: $e');
      return {'totalSessions': 0, 'totalMinutes': 0};
    }
  }

  static Future<void> refreshSessions() async {
    // Force refresh by clearing any cache if needed
    print('🔄 Refreshing reading sessions...');
  }
}
