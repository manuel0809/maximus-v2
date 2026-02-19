import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/ratings_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/completed_trip_card_widget.dart';
import './widgets/review_card_widget.dart';
import './widgets/average_score_display_widget.dart';
import './widgets/rating_composer_widget.dart';

class RatingsReviewsScreen extends StatefulWidget {
  const RatingsReviewsScreen({super.key});

  @override
  State<RatingsReviewsScreen> createState() => _RatingsReviewsScreenState();
}

class _RatingsReviewsScreenState extends State<RatingsReviewsScreen>
    with SingleTickerProviderStateMixin {
  final RatingsService _ratingsService = RatingsService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> completedTrips = [];
  List<Map<String, dynamic>> reviews = [];
  Map<String, double> categoryAverages = {};
  double overallAverage = 0.0;
  bool isLoading = true;
  bool isRefreshing = false;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _subscribeToReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ratingsService.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      final tripsData = await _ratingsService.getCompletedTrips();
      final reviewsData = await _ratingsService.getUserReviews();
      final averages = await _ratingsService.getUserAverageRatings();
      final overall = await _ratingsService.getUserOverallAverage();

      setState(() {
        completedTrips = tripsData;
        reviews = reviewsData;
        categoryAverages = averages;
        overallAverage = overall;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => isRefreshing = true);
    await _loadData();
    setState(() => isRefreshing = false);
  }

  void _subscribeToReviews() {
    _ratingsService.subscribeToReviews((review) {
      _loadData();
    });
  }

  void _handleTripTap(Map<String, dynamic> trip) {
    // Check if trip already has a review
    final hasReview =
        trip['reviews'] != null && (trip['reviews'] as List).isNotEmpty;

    if (hasReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este viaje ya tiene una reseña')),
      );
      return;
    }

    _showRatingComposer(trip);
  }

  void _showRatingComposer(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingComposerWidget(
        trip: trip,
        onSubmit: (rating, categoryRatings, reviewText, photos) async {
          await _submitReview(
            trip['id'],
            rating,
            categoryRatings,
            reviewText,
            photos,
          );
        },
      ),
    );
  }

  Future<void> _submitReview(
    String tripId,
    int overallRating,
    Map<String, int> categoryRatings,
    String reviewText,
    List<String> photoUrls,
  ) async {
    try {
      final review = await _ratingsService.createReview(
        tripId: tripId,
        overallRating: overallRating,
        punctualityRating: categoryRatings['punctuality'],
        cleanlinessRating: categoryRatings['cleanliness'],
        professionalismRating: categoryRatings['professionalism'],
        vehicleConditionRating: categoryRatings['vehicle_condition'],
        reviewText: reviewText,
      );

      // Add photos if any
      for (int i = 0; i < photoUrls.length; i++) {
        await _ratingsService.addReviewPhoto(
          reviewId: review['id'],
          photoUrl: photoUrls[i],
          displayOrder: i,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña enviada exitosamente')),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar reseña: $e')));
      }
    }
  }

  void _handleReviewEdit(Map<String, dynamic> review) {
    // Show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de edición próximamente')),
    );
  }

  Future<void> _handleReviewDelete(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reseña'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta reseña?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _ratingsService.deleteReview(reviewId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Reseña eliminada')));
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredReviews() {
    if (selectedFilter == 'all') return reviews;

    return reviews.where((review) {
      final rating = review['overall_rating'] as int;
      switch (selectedFilter) {
        case '5':
          return rating == 5;
        case '4':
          return rating == 4;
        case '3':
          return rating == 3;
        case '1-2':
          return rating <= 2;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Ratings & Reviews',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: Column(
                children: [
                  // Average Score Display
                  AverageScoreDisplayWidget(
                    overallAverage: overallAverage,
                    categoryAverages: categoryAverages,
                    totalReviews: reviews.length,
                  ),

                  // Tab Bar
                  Container(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: theme.colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Viajes Completados'),
                        Tab(text: 'Mis Reseñas'),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCompletedTripsTab(theme),
                        _buildReviewsTab(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCompletedTripsTab(ThemeData theme) {
    if (completedTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'No hay viajes completados',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: completedTrips.length,
      itemBuilder: (context, index) {
        final trip = completedTrips[index];
        final hasReview =
            trip['reviews'] != null && (trip['reviews'] as List).isNotEmpty;

        return CompletedTripCardWidget(
          trip: trip,
          hasReview: hasReview,
          onTap: () => _handleTripTap(trip),
        );
      },
    );
  }

  Widget _buildReviewsTab(ThemeData theme) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'No has escrito reseñas aún',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final filteredReviews = _getFilteredReviews();

    return Column(
      children: [
        // Filter chips
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Todas', theme),
                SizedBox(width: 2.w),
                _buildFilterChip('5', '5 Estrellas', theme),
                SizedBox(width: 2.w),
                _buildFilterChip('4', '4 Estrellas', theme),
                SizedBox(width: 2.w),
                _buildFilterChip('3', '3 Estrellas', theme),
                SizedBox(width: 2.w),
                _buildFilterChip('1-2', '1-2 Estrellas', theme),
              ],
            ),
          ),
        ),

        // Reviews list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: filteredReviews.length,
            itemBuilder: (context, index) {
              final review = filteredReviews[index];
              return ReviewCardWidget(
                review: review,
                onEdit: () => _handleReviewEdit(review),
                onDelete: () => _handleReviewDelete(review['id']),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, ThemeData theme) {
    final isSelected = selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => selectedFilter = value);
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
    );
  }
}
