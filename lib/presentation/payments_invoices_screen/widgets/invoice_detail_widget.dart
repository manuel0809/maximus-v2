import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class InvoiceDetailWidget extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final Map<String, dynamic> payment;
  final ScrollController scrollController;
  final VoidCallback onDownloadPdf;

  const InvoiceDetailWidget({
    super.key,
    required this.invoice,
    required this.payment,
    required this.scrollController,
    required this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final invoiceNumber = invoice['invoice_number'] as String? ?? 'N/A';
    final invoiceDate = invoice['invoice_date'] as String?;
    final serviceType = invoice['service_type'] as String? ?? 'N/A';
    final vehicleType = invoice['vehicle_type'] as String?;
    final pickupLocation = invoice['pickup_location'] as String?;
    final dropoffLocation = invoice['dropoff_location'] as String?;
    final tripDate = invoice['trip_date'] as String?;
    final driverName = invoice['driver_name'] as String?;
    final driverPhone = invoice['driver_phone'] as String?;
    final distanceKm = (invoice['distance_km'] as num?)?.toDouble();
    final durationMinutes = invoice['duration_minutes'] as int?;

    final baseFare = (invoice['base_fare'] as num?)?.toDouble() ?? 0;
    final distanceCost = (invoice['distance_cost'] as num?)?.toDouble() ?? 0;
    final timeCost = (invoice['time_cost'] as num?)?.toDouble() ?? 0;
    final airportFee = (invoice['airport_fee'] as num?)?.toDouble() ?? 0;
    final peakHourCharge =
        (invoice['peak_hour_charge'] as num?)?.toDouble() ?? 0;
    final additionalFees =
        (invoice['additional_fees'] as num?)?.toDouble() ?? 0;
    final subtotal = (invoice['subtotal'] as num?)?.toDouble() ?? 0;
    final taxAmount = (invoice['tax_amount'] as num?)?.toDouble() ?? 0;
    final gratuity = (invoice['gratuity'] as num?)?.toDouble() ?? 0;
    final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0;

    final paymentStatus = payment['payment_status'] as String? ?? 'unknown';

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(4.w),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invoice Details',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Company header
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MAXIMUS LEVEL GROUP',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Luxury Transportation Services',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),

        // Invoice info
        _buildInfoRow('Invoice Number', invoiceNumber, theme),
        _buildInfoRow(
          'Invoice Date',
          invoiceDate != null
              ? dateFormat.format(DateTime.parse(invoiceDate))
              : 'N/A',
          theme,
        ),
        _buildInfoRow(
          'Payment Status',
          paymentStatus.toUpperCase(),
          theme,
          valueColor: _getStatusColor(paymentStatus, theme),
        ),
        SizedBox(height: 3.h),

        // Service details section
        Text(
          'Service Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow('Service Type', serviceType, theme),
              if (vehicleType != null)
                _buildInfoRow('Vehicle', vehicleType, theme),
              if (tripDate != null)
                _buildInfoRow(
                  'Trip Date',
                  dateFormat.format(DateTime.parse(tripDate)),
                  theme,
                ),
              if (pickupLocation != null)
                _buildInfoRow('Pickup', pickupLocation, theme),
              if (dropoffLocation != null)
                _buildInfoRow('Dropoff', dropoffLocation, theme),
              if (distanceKm != null)
                _buildInfoRow(
                  'Distance',
                  '${distanceKm.toStringAsFixed(1)} km',
                  theme,
                ),
              if (durationMinutes != null)
                _buildInfoRow('Duration', '$durationMinutes min', theme),
            ],
          ),
        ),
        SizedBox(height: 3.h),

        // Driver info (if available)
        if (driverName != null || driverPhone != null) ...[
          Text(
            'Driver Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (driverName != null)
                  _buildInfoRow('Name', driverName, theme),
                if (driverPhone != null)
                  _buildInfoRow('Phone', driverPhone, theme),
              ],
            ),
          ),
          SizedBox(height: 3.h),
        ],

        // Cost breakdown section
        Text(
          'Cost Breakdown',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildCostRow('Base Fare', baseFare, currencyFormat, theme),
              _buildCostRow(
                'Distance Cost',
                distanceCost,
                currencyFormat,
                theme,
              ),
              _buildCostRow('Time Cost', timeCost, currencyFormat, theme),
              if (airportFee > 0)
                _buildCostRow('Airport Fee', airportFee, currencyFormat, theme),
              if (peakHourCharge > 0)
                _buildCostRow(
                  'Peak Hour Charge',
                  peakHourCharge,
                  currencyFormat,
                  theme,
                ),
              if (additionalFees > 0)
                _buildCostRow(
                  'Additional Fees',
                  additionalFees,
                  currencyFormat,
                  theme,
                ),
              Divider(height: 3.h),
              _buildCostRow(
                'Subtotal',
                subtotal,
                currencyFormat,
                theme,
                bold: true,
              ),
              _buildCostRow('Tax', taxAmount, currencyFormat, theme),
              _buildCostRow('Gratuity', gratuity, currencyFormat, theme),
              Divider(height: 3.h),
              _buildCostRow(
                'TOTAL',
                totalAmount,
                currencyFormat,
                theme,
                bold: true,
                large: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),

        // Download button
        ElevatedButton.icon(
          onPressed: onDownloadPdf,
          icon: const Icon(Icons.download),
          label: const Text('Download PDF Invoice'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 2.h),
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(
    String label,
    double amount,
    NumberFormat formatter,
    ThemeData theme, {
    bool bold = false,
    bool large = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              fontSize: large ? 16.sp : null,
            ),
          ),
          Text(
            formatter.format(amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: large ? 16.sp : null,
              color: large ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'completed':
        return theme.colorScheme.primary;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return theme.colorScheme.error;
      case 'refunded':
        return Colors.blue;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
