import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CategoryFilterWidget extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;
  final String Function(String?) getCategoryIcon;

  const CategoryFilterWidget({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.getCategoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryButton(
            context: context,
            categoryId: null,
            name: 'Todos',
            icon: '🚗',
            basePrice: null,
            isSelected: selectedCategoryId == null,
          ),
          SizedBox(width: 3.w),
          ...categories.map((category) {
            return Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: _buildCategoryButton(
                context: context,
                categoryId: category['id'],
                name: category['name'],
                icon: getCategoryIcon(category['icon']),
                basePrice: category['base_price_per_day'],
                isSelected: selectedCategoryId == category['id'],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required BuildContext context,
    required String? categoryId,
    required String name,
    required String icon,
    required dynamic basePrice,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onCategorySelected(categoryId),
      child: Container(
        width: 28.w,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF8B1538) : Colors.grey.shade300,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          color: isSelected
              ? const Color(0xFF8B1538).withAlpha(26)
              : Colors.white,
        ),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 20.sp)),
            SizedBox(height: 1.h),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: isSelected ? const Color(0xFF8B1538) : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            if (basePrice != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                'Desde \$$basePrice/día',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
