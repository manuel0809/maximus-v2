import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../widgets/custom_image_widget.dart';

class ReviewCardWidget extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReviewCardWidget({
    super.key,
    required this.review,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'es').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = review['trips'] as Map<String, dynamic>?;
    final photos = review['review_photos'] as List?;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with trip info and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip?['service_type'] ?? 'Servicio',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        trip?['vehicle_type'] ?? 'Vehículo',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Star rating
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < (review['overall_rating'] as int)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                SizedBox(width: 2.w),
                Text(
                  '${review['overall_rating']}.0',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(review['created_at']),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Category ratings
            if (review['punctuality_rating'] != null) ...[
              SizedBox(height: 1.5.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: [
                  if (review['punctuality_rating'] != null)
                    _buildCategoryChip(
                      'Puntualidad',
                      review['punctuality_rating'],
                      theme,
                    ),
                  if (review['cleanliness_rating'] != null)
                    _buildCategoryChip(
                      'Limpieza',
                      review['cleanliness_rating'],
                      theme,
                    ),
                  if (review['professionalism_rating'] != null)
                    _buildCategoryChip(
                      'Profesionalismo',
                      review['professionalism_rating'],
                      theme,
                    ),
                  if (review['vehicle_condition_rating'] != null)
                    _buildCategoryChip(
                      'Vehículo',
                      review['vehicle_condition_rating'],
                      theme,
                    ),
                ],
              ),
            ],

            // Review text
            if (review['review_text'] != null &&
                (review['review_text'] as String).isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                review['review_text'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],

            // Photos
            if (photos != null && photos.isNotEmpty) ...[
              SizedBox(height: 2.h),
              SizedBox(
                height: 15.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return Container(
                      margin: EdgeInsets.only(right: 2.w),
                      width: 20.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CustomImageWidget(
                          imageUrl: photo['photo_url'],
                          fit: BoxFit.cover,
                          semanticLabel: photo['caption'] ?? 'Foto de reseña',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Provider response
            if (review['provider_response'] != null) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Respuesta del proveedor',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      review['provider_response'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Edited indicator
            if (review['is_edited'] == true) ...[
              SizedBox(height: 1.h),
              Text(
                'Editado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int rating, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 1.w),
          Icon(Icons.star, size: 12, color: Colors.amber),
          Text(
            '$rating',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
