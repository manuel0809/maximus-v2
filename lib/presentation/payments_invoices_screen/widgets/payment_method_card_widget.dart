import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PaymentMethodCardWidget extends StatelessWidget {
  final Map<String, dynamic> paymentMethod;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const PaymentMethodCardWidget({
    super.key,
    required this.paymentMethod,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final methodType = paymentMethod['method_type'] as String? ?? 'unknown';
    final isDefault = paymentMethod['is_default'] as bool? ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getMethodIcon(methodType),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMethodTitle(paymentMethod),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _getMethodSubtitle(paymentMethod),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                if (!isDefault)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSetDefault,
                      child: const Text('Set as Default'),
                    ),
                  ),
                if (!isDefault) SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Payment Method'),
                          content: const Text(
                            'Are you sure you want to delete this payment method?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(String methodType) {
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

  String _getMethodTitle(Map<String, dynamic> method) {
    final methodType = method['method_type'] as String?;
    switch (methodType) {
      case 'credit_card':
        return method['card_brand'] as String? ?? 'Credit Card';
      case 'debit_card':
        return method['card_brand'] as String? ?? 'Debit Card';
      case 'digital_wallet':
        return method['wallet_provider'] as String? ?? 'Digital Wallet';
      case 'bank_account':
        return method['bank_name'] as String? ?? 'Bank Account';
      default:
        return 'Payment Method';
    }
  }

  String _getMethodSubtitle(Map<String, dynamic> method) {
    final methodType = method['method_type'] as String?;
    switch (methodType) {
      case 'credit_card':
      case 'debit_card':
        final lastFour = method['card_last_four'] as String? ?? '****';
        final expMonth = method['card_exp_month'] as int?;
        final expYear = method['card_exp_year'] as int?;
        if (expMonth != null && expYear != null) {
          return '•••• $lastFour | Exp: ${expMonth.toString().padLeft(2, '0')}/$expYear';
        }
        return '•••• $lastFour';
      case 'digital_wallet':
        return 'Digital Wallet';
      case 'bank_account':
        final lastFour = method['account_last_four'] as String? ?? '****';
        return '•••• $lastFour';
      default:
        return 'Payment method';
    }
  }
}
