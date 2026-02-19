import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

class RatingComposerWidget extends StatefulWidget {
  final Map<String, dynamic> trip;
  final Function(
    int overallRating,
    Map<String, int> categoryRatings,
    String reviewText,
    List<String> photoUrls,
  )
  onSubmit;

  const RatingComposerWidget({
    super.key,
    required this.trip,
    required this.onSubmit,
  });

  @override
  State<RatingComposerWidget> createState() => _RatingComposerWidgetState();
}

class _RatingComposerWidgetState extends State<RatingComposerWidget> {
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  int overallRating = 0;
  Map<String, int> categoryRatings = {
    'punctuality': 0,
    'cleanliness': 0,
    'professionalism': 0,
    'vehicle_condition': 0,
  };
  List<String> photoUrls = [];
  bool isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        // In production, upload to Supabase Storage and get URLs
        // For now, using placeholder URLs from Unsplash
        final placeholders = [
          'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2',
          'https://images.unsplash.com/photo-1555215695-3004980ad54e',
          'https://images.unsplash.com/photo-1639927659853-4c53905a22ad',
        ];

        setState(() {
          for (int i = 0; i < images.length && i < 3; i++) {
            photoUrls.add(placeholders[i % placeholders.length]);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imágenes: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      photoUrls.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una calificación')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await widget.onSubmit(
        overallRating,
        categoryRatings,
        _reviewController.text,
        photoUrls,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calificar Viaje',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Trip info
              Text(
                widget.trip['service_type'] ?? 'Servicio',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.trip['vehicle_type'] ?? 'Vehículo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 3.h),

              // Overall rating
              Text(
                'Calificación General',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => overallRating = index + 1);
                    },
                    child: Icon(
                      index < overallRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),

              SizedBox(height: 3.h),

              // Category ratings
              Text(
                'Calificaciones por Categoría (Opcional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              _buildCategoryRating('Puntualidad', 'punctuality', theme),
              _buildCategoryRating('Limpieza', 'cleanliness', theme),
              _buildCategoryRating('Profesionalismo', 'professionalism', theme),
              _buildCategoryRating(
                'Condición del Vehículo',
                'vehicle_condition',
                theme,
              ),

              SizedBox(height: 3.h),

              // Review text
              Text(
                'Escribe tu Reseña (Opcional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Comparte tu experiencia...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),

              SizedBox(height: 2.h),

              // Photo upload
              Text(
                'Agregar Fotos (Opcional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              if (photoUrls.isEmpty)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 15.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Toca para agregar fotos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 15.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photoUrls.length + 1,
                        itemBuilder: (context, index) {
                          if (index == photoUrls.length) {
                            return GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 20.w,
                                margin: EdgeInsets.only(right: 2.w),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }

                          return Container(
                            width: 20.w,
                            margin: EdgeInsets.only(right: 2.w),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Center(
                                      child: Icon(Icons.image),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 3.h),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Enviar Reseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRating(String label, String key, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() => categoryRatings[key] = index + 1);
                },
                child: Icon(
                  index < (categoryRatings[key] ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
