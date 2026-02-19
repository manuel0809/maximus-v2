import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AverageScoreDisplayWidget extends StatelessWidget {
  final double overallAverage;
  final Map<String, double> categoryAverages;
  final int totalReviews;

  const AverageScoreDisplayWidget({
    super.key,
    required this.overallAverage,
    required this.categoryAverages,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Overall score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                overallAverage.toStringAsFixed(1),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 2.w),
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < overallAverage.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '$totalReviews reseñas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Category breakdowns
          _buildCategoryBar(
            'Puntualidad',
            categoryAverages['punctuality'] ?? 0.0,
            Icons.access_time,
            theme,
          ),
          SizedBox(height: 1.5.h),
          _buildCategoryBar(
            'Limpieza',
            categoryAverages['cleanliness'] ?? 0.0,
            Icons.cleaning_services,
            theme,
          ),
          SizedBox(height: 1.5.h),
          _buildCategoryBar(
            'Profesionalismo',
            categoryAverages['professionalism'] ?? 0.0,
            Icons.person,
            theme,
          ),
          SizedBox(height: 1.5.h),
          _buildCategoryBar(
            'Condición del Vehículo',
            categoryAverages['vehicle_condition'] ?? 0.0,
            Icons.directions_car,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(
    String label,
    double rating,
    IconData icon,
    ThemeData theme,
  ) {
    final percentage = rating / 5.0;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            Text(
              rating.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
