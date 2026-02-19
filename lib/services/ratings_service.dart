import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class RatingsService {
  static RatingsService? _instance;
  static RatingsService get instance => _instance ??= RatingsService._();

  RatingsService._();

  final SupabaseClient _supabase = SupabaseService.instance.client;

  // Get completed trips for current user
  Future<List<Map<String, dynamic>>> getCompletedTrips() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('trips')
          .select('*, reviews(id)')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error loading completed trips: $e');
    }
  }

  // Get all reviews for current user
  Future<List<Map<String, dynamic>>> getUserReviews() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('reviews')
          .select('*, trips(*), review_photos(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error loading reviews: $e');
    }
  }

  // Create new review
  Future<Map<String, dynamic>> createReview({
    required String tripId,
    required int overallRating,
    int? punctualityRating,
    int? cleanlinessRating,
    int? professionalismRating,
    int? vehicleConditionRating,
    String? reviewText,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get trip details to extract driver_id
      final trip = await _supabase
          .from('trips')
          .select('driver_id')
          .eq('id', tripId)
          .single();

      final response = await _supabase
          .from('reviews')
          .insert({
            'trip_id': tripId,
            'user_id': userId,
            'driver_id': trip['driver_id'],
            'overall_rating': overallRating,
            'punctuality_rating': punctualityRating,
            'cleanliness_rating': cleanlinessRating,
            'professionalism_rating': professionalismRating,
            'vehicle_condition_rating': vehicleConditionRating,
            'review_text': reviewText,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error creating review: $e');
    }
  }

  // Update existing review
  Future<void> updateReview({
    required String reviewId,
    required int overallRating,
    int? punctualityRating,
    int? cleanlinessRating,
    int? professionalismRating,
    int? vehicleConditionRating,
    String? reviewText,
  }) async {
    try {
      await _supabase
          .from('reviews')
          .update({
            'overall_rating': overallRating,
            'punctuality_rating': punctualityRating,
            'cleanliness_rating': cleanlinessRating,
            'professionalism_rating': professionalismRating,
            'vehicle_condition_rating': vehicleConditionRating,
            'review_text': reviewText,
            'is_edited': true,
          })
          .eq('id', reviewId);
    } catch (e) {
      throw Exception('Error updating review: $e');
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw Exception('Error deleting review: $e');
    }
  }

  // Add photo to review
  Future<void> addReviewPhoto({
    required String reviewId,
    required String photoUrl,
    String? caption,
    int displayOrder = 0,
  }) async {
    try {
      await _supabase.from('review_photos').insert({
        'review_id': reviewId,
        'photo_url': photoUrl,
        'caption': caption,
        'display_order': displayOrder,
      });
    } catch (e) {
      throw Exception('Error adding review photo: $e');
    }
  }

  // Delete review photo
  Future<void> deleteReviewPhoto(String photoId) async {
    try {
      await _supabase.from('review_photos').delete().eq('id', photoId);
    } catch (e) {
      throw Exception('Error deleting review photo: $e');
    }
  }

  // Get average ratings for current user
  Future<Map<String, double>> getUserAverageRatings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.rpc(
        'get_user_category_averages',
        params: {'p_user_id': userId},
      );

      if (response == null || response.isEmpty) {
        return {
          'punctuality': 0.0,
          'cleanliness': 0.0,
          'professionalism': 0.0,
          'vehicle_condition': 0.0,
        };
      }

      final data = response[0];
      return {
        'punctuality': (data['punctuality'] ?? 0.0).toDouble(),
        'cleanliness': (data['cleanliness'] ?? 0.0).toDouble(),
        'professionalism': (data['professionalism'] ?? 0.0).toDouble(),
        'vehicle_condition': (data['vehicle_condition'] ?? 0.0).toDouble(),
      };
    } catch (e) {
      return {
        'punctuality': 0.0,
        'cleanliness': 0.0,
        'professionalism': 0.0,
        'vehicle_condition': 0.0,
      };
    }
  }

  // Get overall average rating for current user
  Future<double> getUserOverallAverage() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('reviews')
          .select('overall_rating')
          .eq('user_id', userId);

      if (response.isEmpty) return 0.0;

      final ratings = List<Map<String, dynamic>>.from(response);
      final sum = ratings.fold<int>(
        0,
        (prev, curr) => prev + (curr['overall_rating'] as int),
      );

      return sum / ratings.length;
    } catch (e) {
      return 0.0;
    }
  }

  // Subscribe to reviews updates
  RealtimeChannel subscribeToReviews(Function(Map<String, dynamic>) onUpdate) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .channel('reviews_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reviews',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  // Unsubscribe from reviews
  void unsubscribe() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _supabase.removeChannel(_supabase.channel('reviews_$userId'));
    }
  }
}
