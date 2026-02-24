import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ActiveRentalCardWidget extends StatelessWidget {
  final Map<String, dynamic> rental;
  final VoidCallback onTap;

  const ActiveRentalCardWidget({
    super.key,
    required this.rental,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = rental['vehicles'] ?? {};

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF8B1538).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B1538).withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1538),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.vpn_key, color: Colors.white),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Renta en curso',
                    style: TextStyle(
                      color: const Color(0xFF8B1538),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    '${vehicle['brand']} ${vehicle['model']}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8B1538)),
          ],
        ),
      ),
    );
  }
}
