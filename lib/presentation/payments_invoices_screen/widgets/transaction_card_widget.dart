import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class TransactionCardWidget extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onTap;

  const TransactionCardWidget({
    super.key,
    required this.payment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final trip = payment['trips'] as Map<String, dynamic>?;
    final rental = payment['rentals'] as Map<String, dynamic>?;
    final paymentMethod = payment['payment_methods'] as Map<String, dynamic>?;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final status = payment['payment_status'] as String? ?? 'unknown';
    final paymentDate = payment['payment_date'] as String?;
    final transactionRef = payment['transaction_reference'] as String? ?? 'N/A';

    final isRental = rental != null;
    final serviceType = isRental ? 'Car Rental' : (trip?['service_type'] as String? ?? 'Service');
    final vehicleName = isRental ? '${rental['vehicles']['brand']} ${rental['vehicles']['model']}' : null;
    final pickupLocation = isRental ? rental['pickup_location'] : trip?['pickup_location'];
    final dropoffLocation = isRental ? rental['dropoff_location'] : trip?['dropoff_location'];

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.error;
        break;
      case 'refunded':
        statusColor = Colors.blue;
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
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
                          serviceType,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        if (paymentDate != null)
                          Text(
                            dateFormat.format(DateTime.parse(paymentDate)),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(amount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            SizedBox(width: 1.w),
                            Text(
                              status.toUpperCase(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (pickupLocation != null || dropoffLocation != null) ...[
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        '${pickupLocation ?? 'N/A'} → ${dropoffLocation ?? 'N/A'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (paymentMethod != null)
                    Row(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(paymentMethod['method_type']),
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _getPaymentMethodLabel(paymentMethod),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    transactionRef,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              if (isRental && status == 'completed') ...[
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                       Navigator.pushNamed(
                        context,
                        '/rental-feedback-screen',
                        arguments: {
                          'rentalId': rental['id'],
                          'vehicleName': vehicleName,
                        },
                      );
                    },
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Calificar Experiencia'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B1538),
                      side: const BorderSide(color: Color(0xFF8B1538)),
                      padding: EdgeInsets.symmetric(vertical: 0.5.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String? methodType) {
    switch (methodType) {
      case 'credit_card':
      case 'debit_card':
        return Icons.credit_card;
      case 'digital_wallet':
        return Icons.account_balance_wallet;
      case 'bank_account':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodLabel(Map<String, dynamic> method) {
    final methodType = method['method_type'] as String?;
    switch (methodType) {
      case 'credit_card':
      case 'debit_card':
        final brand = method['card_brand'] as String? ?? '';
        final lastFour = method['card_last_four'] as String? ?? '';
        return '$brand ••$lastFour';
      case 'digital_wallet':
        return method['wallet_provider'] as String? ?? 'Digital Wallet';
      case 'bank_account':
        final bank = method['bank_name'] as String? ?? 'Bank';
        final lastFour = method['account_last_four'] as String? ?? '';
        return '$bank ••$lastFour';
      default:
        return 'Payment Method';
    }
  }
}
