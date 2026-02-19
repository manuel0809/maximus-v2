import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NotificationFilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NotificationFilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B1538) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
