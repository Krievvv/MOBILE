import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final _supabase = Supabase.instance.client;

  static Future<UserProfile?> getCurrentProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle instead of single to handle no results

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  static Future<UserProfile?> createProfile({
    required String username,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final profileData = {
        'id': userId,
        'username': username,
        'full_name': fullName,
        'bio': bio,
        'avatar_url': avatarUrl,
      };

      final response = await _supabase
          .from('profiles')
          .insert(profileData)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error creating profile: $e');
      return null;
    }
  }

  static Future<UserProfile?> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};

      if (username != null) updateData['username'] = username;
      if (fullName != null) updateData['full_name'] = fullName;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      // Only update if there's something to update
      if (updateData.isEmpty) {
        return await getCurrentProfile();
      }

      final response = await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  static Future<bool> checkUsernameAvailable(String username, {String? excludeUserId}) async {
    try {
      var query = _supabase
          .from('profiles')
          .select('id')
          .eq('username', username);

      if (excludeUserId != null) {
        query = query.neq('id', excludeUserId);
      }

      final response = await query.maybeSingle();
      return response == null; // Available if no user found with this username
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  static Future<Map<String, int>> getBookStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'total': 0, 'read': 0, 'unread': 0};

      final response = await _supabase
          .from('books')
          .select('is_read')
          .eq('user_id', userId);

      final books = response as List;
      final total = books.length;
      final read = books.where((book) => book['is_read'] == true).length;
      final unread = total - read;

      return {
        'total': total,
        'read': read,
        'unread': unread,
      };
    } catch (e) {
      print('Error getting book stats: $e');
      return {'total': 0, 'read': 0, 'unread': 0};
    }
  }
}
