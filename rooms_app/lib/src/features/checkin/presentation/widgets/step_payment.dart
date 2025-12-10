import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/checkin/presentation/providers/checkin_providers.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Step 2: Payment Information
class StepPayment extends ConsumerStatefulWidget {
  final Room room;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepPayment({
    super.key,
    required this.room,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<StepPayment> createState() => _StepPaymentState();
}

class _StepPaymentState extends ConsumerState<StepPayment> {
  final _paidController = TextEditingController();
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _paidController.text = '0';
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkinState = ref.watch(checkinStateProvider);
    final nights = checkinState.stayDuration;
    final totalAmount = widget.room.pricePerNight * nights;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBillSummary(checkinState, totalAmount, nights),
          const SizedBox(height: 24),
          _buildSectionTitle('Payment Method', Icons.payment),
          const SizedBox(height: 12),
          _buildPaymentMethodSelector(),
          const SizedBox(height: 24),

          _buildSectionTitle('Amount Received', Icons.currency_rupee),
          const SizedBox(height: 12),
          _buildAmountInput(totalAmount),
          const SizedBox(height: 12),
          _buildQuickAmountButtons(totalAmount),
          const SizedBox(height: 32),

          _buildNavigationButtons(totalAmount),
        ],
      ),
    );
  }

  Widget _buildBillSummary(CheckinState state, double total, int nights) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.warning),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Bill Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildBillRow('Guest', state.customer?.name ?? '-'),
          _buildBillRow(
            'Room',
            '${widget.room.roomNumber} (${widget.room.roomType})',
          ),
          _buildBillRow(
            'Rate',
            '₹${widget.room.pricePerNight.toStringAsFixed(0)}/night',
          ),
          _buildBillRow('Nights', '$nights'),
          _buildBillRow('Guests', '${state.guestCount}'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.black),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    final methods = [
      {'id': 'cash', 'label': 'Cash', 'icon': Icons.money},
      {'id': 'upi', 'label': 'UPI', 'icon': Icons.qr_code},
      {'id': 'card', 'label': 'Card', 'icon': Icons.credit_card},
    ];

    return Row(
      children: methods.map((method) {
        final isSelected = _paymentMethod == method['id'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () =>
                  setState(() => _paymentMethod = method['id'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.black : AppColors.grey300,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      method['icon'] as IconData,
                      size: 32,
                      color: isSelected ? AppColors.white : AppColors.black,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      method['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.white : AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountInput(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          const Text(
            '₹',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _paidController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'of ₹${total.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                _getPaymentStatus(total),
                style: TextStyle(
                  color: _getPaymentStatusColor(total),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButtons(double total) {
    final amounts = [
      {'label': 'Full', 'value': total},
      {'label': 'Half', 'value': total / 2},
      {'label': '₹1000', 'value': 1000.0},
      {'label': '₹500', 'value': 500.0},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amounts.map((amount) {
        return InkWell(
          onTap: () {
            _paidController.text = (amount['value'] as double).toStringAsFixed(
              0,
            );
            setState(() {});
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Text(
              amount['label'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons(double total) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.grey400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back),
                SizedBox(width: 8),
                Text('Back'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => _handleNext(total),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roomFree,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next: Confirm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getPaymentStatus(double total) {
    final paid = double.tryParse(_paidController.text) ?? 0;
    if (paid >= total) return 'Full Payment';
    if (paid > 0) return 'Partial';
    return 'Pending';
  }

  Color _getPaymentStatusColor(double total) {
    final paid = double.tryParse(_paidController.text) ?? 0;
    if (paid >= total) return AppColors.success;
    if (paid > 0) return AppColors.warning;
    return AppColors.error;
  }

  void _handleNext(double total) {
    final paid = double.tryParse(_paidController.text) ?? 0;
    ref.read(checkinStateProvider.notifier).setPayment(total, paid);
    widget.onNext();
  }
}
