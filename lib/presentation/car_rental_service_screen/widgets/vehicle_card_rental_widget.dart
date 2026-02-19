import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VehicleCardRentalWidget extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final DateTime? pickupDate;
  final DateTime? dropoffDate;
  final VoidCallback onReservePressed;
  final bool isSelected;
  final VoidCallback? onSelected;

  const VehicleCardRentalWidget({
    super.key,
    required this.vehicle,
    required this.pickupDate,
    required this.dropoffDate,
    required this.onReservePressed,
    this.isSelected = false,
    this.onSelected,
  });

  String _getCategoryName() {
    final category = vehicle['vehicle_categories'];
    if (category != null && category is Map) {
      return category['name'] ?? '';
    }
    return '';
  }

  Color _getCategoryColor() {
    final categoryName = _getCategoryName();
    switch (categoryName) {
      case 'Económico':
        return Colors.green;
      case 'SUV':
        return Colors.blue;
      case 'Lujo':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = vehicle['image_urls'] as List?;
    final imageUrl = (imageUrls != null && imageUrls.isNotEmpty)
        ? imageUrls[0]
        : null;
    final features = vehicle['features'] as List?;
    final pricePerDay = vehicle['price_per_day'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: isSelected ? Border.all(color: const Color(0xFF8B1538), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 18.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 18.h,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 18.h,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.directions_car, size: 50),
                        ),
                      )
                    : Container(
                        height: 18.h,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.directions_car, size: 50),
                        ),
                      ),
              ),
              if (onSelected != null)
                Positioned(
                  top: 1.h,
                  left: 2.w,
                  child: IconButton(
                    onPressed: onSelected,
                    icon: Icon(
                      isSelected ? Icons.check_circle : Icons.add_circle_outline,
                      color: isSelected ? const Color(0xFF8B1538) : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              Positioned(
                top: 2.h,
                right: 3.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withAlpha(230),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    _getCategoryName(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicle['brand']} ${vehicle['model']}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${vehicle['year']} • ${vehicle['seats']} asientos • ${vehicle['transmission']}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$$pricePerDay',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B1538),
                          ),
                        ),
                        Text(
                          '/día',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 1.h),

                if (features != null && features.isNotEmpty)
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: features.take(3).map((feature) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '✓ $feature',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                if (features != null && features.length > 3) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    '+${features.length - 3} más',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                SizedBox(height: 1.5.h),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onReservePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1538),
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Reservar ahora',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
