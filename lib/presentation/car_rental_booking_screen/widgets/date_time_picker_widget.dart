import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class DateTimePickerWidget extends StatelessWidget {
  final DateTime? pickupDate;
  final TimeOfDay? pickupTime;
  final DateTime? returnDate;
  final TimeOfDay? returnTime;
  final Function(DateTime) onPickupDateSelected;
  final Function(TimeOfDay) onPickupTimeSelected;
  final Function(DateTime) onReturnDateSelected;
  final Function(TimeOfDay) onReturnTimeSelected;

  const DateTimePickerWidget({
    super.key,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.onPickupDateSelected,
    required this.onPickupTimeSelected,
    required this.onReturnDateSelected,
    required this.onReturnTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Pickup Date and Time
          _buildDateTimeRow(
            context,
            'Recogida',
            pickupDate,
            pickupTime,
            () => _selectDate(context, true),
            () => _selectTime(context, true),
          ),
          SizedBox(height: 2.h),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: 2.h),
          // Return Date and Time
          _buildDateTimeRow(
            context,
            'Devolución',
            returnDate,
            returnTime,
            () => _selectDate(context, false),
            () => _selectTime(context, false),
          ),
          // Duration Display
          if (pickupDate != null && returnDate != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Duración: ${_calculateDuration()} días',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(
    BuildContext context,
    String label,
    DateTime? date,
    TimeOfDay? time,
    VoidCallback onDateTap,
    VoidCallback onTimeTap,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            // Date Selector
            Expanded(
              child: GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'calendar_today',
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          date != null
                              ? DateFormat('dd/MM/yyyy').format(date)
                              : 'Seleccionar fecha',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: date != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            // Time Selector
            Expanded(
              child: GestureDetector(
                onTap: onTimeTap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'access_time',
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          time != null
                              ? time.format(context)
                              : 'Seleccionar hora',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: time != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime initialDate = DateTime.now();
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickup
          ? (pickupDate ?? initialDate)
          : (returnDate ?? pickupDate ?? initialDate),
      firstDate: isPickup ? firstDate : (pickupDate ?? firstDate),
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isPickup) {
        onPickupDateSelected(picked);
      } else {
        onReturnDateSelected(picked);
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay initialTime = TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isPickup
          ? (pickupTime ?? initialTime)
          : (returnTime ?? initialTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isPickup) {
        onPickupTimeSelected(picked);
      } else {
        onReturnTimeSelected(picked);
      }
    }
  }

  int _calculateDuration() {
    if (pickupDate == null || returnDate == null) return 0;
    return returnDate!.difference(pickupDate!).inDays + 1;
  }
}
