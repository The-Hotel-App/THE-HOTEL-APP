import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/presentation/providers/booking_providers.dart';
import 'package:rooms/src/features/bookings/presentation/providers/new_booking_providers.dart';
import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';
import 'package:rooms/src/features/daybook/presentation/providers/daybook_providers.dart';

/// Dialog for collecting remaining payment for a booking
class CollectPaymentDialog extends ConsumerStatefulWidget {
  final Booking booking;

  const CollectPaymentDialog({
    super.key,
    required this.booking,
  });

  /// Show the collect payment dialog
  static Future<bool?> show(BuildContext context, Booking booking) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectPaymentDialog(booking: booking),
    );
  }

  @override
  ConsumerState<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends ConsumerState<CollectPaymentDialog> {
  final _amountController = TextEditingController();
  PaymentMode _selectedMode = PaymentMode.cash;
  bool _isProcessing = false;

  double get pendingAmount => widget.booking.pendingAmount;

  @override
  void initState() {
    super.initState();
    // Pre-fill with pending amount
    _amountController.text = pendingAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collect Payment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Room ${widget.booking.roomNumber} - ${widget.booking.customerName}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Payment summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Amount', '₹${widget.booking.totalAmount.toStringAsFixed(0)}'),
                    _buildSummaryRow('Already Paid', '₹${widget.booking.paidAmount.toStringAsFixed(0)}', color: AppColors.success),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Pending',
                      '₹${pendingAmount.toStringAsFixed(0)}',
                      color: AppColors.error,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Amount input
              const Text(
                'Amount to Collect',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // Quick amount buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAmountButton('Full', pendingAmount),
                  _buildQuickAmountButton('Half', pendingAmount / 2),
                  if (pendingAmount > 1000) _buildQuickAmountButton('₹1000', 1000),
                  if (pendingAmount > 500) _buildQuickAmountButton('₹500', 500),
                ],
              ),
              const SizedBox(height: 24),
              // Payment mode
              const Text(
                'Payment Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentModeSelector(),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.grey400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isProcessing || amount <= 0 ? null : _collectPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Collect ₹${amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String label, double amount) {
    return InkWell(
      onTap: () {
        _amountController.text = amount.toStringAsFixed(0);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildPaymentModeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMode.values.map((mode) {
        final isSelected = _selectedMode == mode;
        return InkWell(
          onTap: () => setState(() => _selectedMode = mode),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.black : AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.black : AppColors.grey300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPaymentModeIcon(mode),
                  size: 18,
                  color: isSelected ? AppColors.white : AppColors.grey600,
                ),
                const SizedBox(width: 8),
                Text(
                  mode.displayName,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getPaymentModeIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.money;
      case PaymentMode.upi:
        return Icons.qr_code;
      case PaymentMode.card:
        return Icons.credit_card;
      case PaymentMode.bankTransfer:
        return Icons.account_balance;
      case PaymentMode.other:
        return Icons.more_horiz;
    }
  }

  Future<void> _collectPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isProcessing = true);

    try {
      final hotel = ref.read(currentHotelProvider);
      final user = ref.read(currentUserProvider).valueOrNull;
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final daybookRepo = ref.read(dayBookRepositoryProvider);

      if (hotel == null) throw Exception('No hotel selected');

      // Update booking payment
      await bookingRepo.updatePayment(widget.booking.id, amount);

      // Record in daybook
      try {
        final todaySummary = await daybookRepo.getTodaySummary(hotel.hotelId);

        final transaction = Transaction(
          id: '',
          hotelId: hotel.hotelId,
          daybookId: todaySummary.id,
          type: TransactionType.income,
          category: TransactionCategory.roomPayment,
          amount: amount,
          description: 'Room ${widget.booking.roomNumber} - ${widget.booking.customerName} (${_selectedMode.displayName})',
          createdAt: DateTime.now(),
          createdBy: user?.id ?? '',
          bookingId: widget.booking.id,
        );

        await daybookRepo.addTransaction(transaction);
      } catch (e) {
        debugPrint('Failed to record payment in daybook: $e');
      }

      // Invalidate providers to refresh data
      ref.invalidate(bookingsProvider);
      ref.invalidate(todayDayBookProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ₹${amount.toStringAsFixed(0)} collected'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
