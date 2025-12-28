import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/utils/tariff_calculator.dart';
import 'package:rooms/src/features/bookings/data/repositories/supabase_booking_repository.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/presentation/providers/booking_providers.dart';

/// Page for extending a guest's stay with tariff calculation preview
class ExtendStayPage extends ConsumerStatefulWidget {
  final Booking booking;
  final int tariffDurationHours;
  final double tariffAmount;
  final double gracePeriodHours;

  const ExtendStayPage({
    super.key,
    required this.booking,
    required this.tariffDurationHours,
    required this.tariffAmount,
    required this.gracePeriodHours,
  });

  @override
  ConsumerState<ExtendStayPage> createState() => _ExtendStayPageState();
}

class _ExtendStayPageState extends ConsumerState<ExtendStayPage> {
  late DateTime _newCheckOut;
  bool _isSubmitting = false;

  // Current cost calculation
  late TariffResult _currentResult;
  late TariffResult _newResult;

  @override
  void initState() {
    super.initState();
    // Initialize with current checkout + tariff duration as default extension
    _newCheckOut = widget.booking.checkOut.add(
      Duration(hours: widget.tariffDurationHours),
    );
    _calculateCosts();
  }

  void _calculateCosts() {
    _currentResult = TariffCalculator.calculate(
      checkIn: widget.booking.checkIn,
      checkOut: widget.booking.checkOut,
      tariffDurationHours: widget.tariffDurationHours,
      tariffAmount: widget.tariffAmount,
      gracePeriodHours: widget.gracePeriodHours,
    );

    _newResult = TariffCalculator.calculate(
      checkIn: widget.booking.checkIn,
      checkOut: _newCheckOut,
      tariffDurationHours: widget.tariffDurationHours,
      tariffAmount: widget.tariffAmount,
      gracePeriodHours: widget.gracePeriodHours,
    );
  }

  double get _additionalCharge =>
      _newResult.totalAmount - _currentResult.totalAmount;

  Future<void> _submitExtension() async {
    if (_additionalCharge < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New checkout time must be after current checkout'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository =
          ref.read(bookingRepositoryProvider) as SupabaseBookingRepository;
      await repository.updateBookingFields(
        bookingId: widget.booking.id,
        checkOut: _newCheckOut,
        totalAmount: _newResult.totalAmount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stay extended to ${DateFormat('d MMM, h:mm a').format(_newCheckOut)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return success
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Extend Stay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guest info card
            _buildGuestInfoCard(),
            const SizedBox(height: 16),

            // Current checkout info
            _buildCurrentCheckoutCard(),
            const SizedBox(height: 16),

            // New checkout picker
            _buildNewCheckoutCard(),
            const SizedBox(height: 16),

            // Cost breakdown
            _buildCostBreakdownCard(),
            const SizedBox(height: 24),

            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Room ${widget.booking.allRoomNumbers}',
                  style: TextStyle(color: AppColors.grey600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCheckoutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT BOOKING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildDateTimeRow(
            'Check In',
            widget.booking.checkIn,
            Icons.login_rounded,
          ),
          const SizedBox(height: 8),
          _buildDateTimeRow(
            'Check Out',
            widget.booking.checkOut,
            Icons.logout_rounded,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppColors.grey600),
              const SizedBox(width: 8),
              Text(
                'Duration: ${_currentResult.formattedDuration}',
                style: TextStyle(color: AppColors.grey600),
              ),
              const Spacer(),
              Text(
                '${_currentResult.cycles} tariff cycle${_currentResult.cycles > 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(String label, DateTime dateTime, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey600),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: AppColors.grey600)),
        Text(
          DateFormat('d MMM yyyy, h:mm a').format(dateTime),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildNewCheckoutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_calendar, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'NEW CHECKOUT TIME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickNewCheckoutDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat(
                        'EEEE, d MMM yyyy • h:mm a',
                      ).format(_newCheckOut),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.edit, size: 18, color: AppColors.grey600),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'New duration: ${_newResult.formattedDuration}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${_newResult.cycles} tariff cycle${_newResult.cycles > 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickNewCheckoutDateTime() async {
    // Pick date first
    final date = await showDatePicker(
      context: context,
      initialDate: _newCheckOut,
      firstDate: widget.booking.checkOut,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    // Pick time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_newCheckOut),
    );

    if (time == null || !mounted) return;

    setState(() {
      _newCheckOut = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _calculateCosts();
    });
    HapticFeedback.selectionClick();
  }

  Widget _buildCostBreakdownCard() {
    final additionalCycles = _newResult.cycles - _currentResult.cycles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COST BREAKDOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildCostRow(
            'Current booking',
            '₹${_currentResult.totalAmount.toStringAsFixed(0)}',
            '${_currentResult.cycles} cycle${_currentResult.cycles > 1 ? 's' : ''}',
          ),
          const Divider(height: 24),
          _buildCostRow(
            'Extended booking',
            '₹${_newResult.totalAmount.toStringAsFixed(0)}',
            '${_newResult.cycles} cycle${_newResult.cycles > 1 ? 's' : ''}',
          ),
          const Divider(height: 24),
          _buildCostRow(
            'Additional charge',
            '₹${_additionalCharge.toStringAsFixed(0)}',
            additionalCycles > 0
                ? '+$additionalCycles cycle${additionalCycles > 1 ? 's' : ''}'
                : 'No additional cycles',
            isHighlighted: true,
          ),
          if (_additionalCharge > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guest will be charged ₹${_additionalCharge.toStringAsFixed(0)} for the extension',
                      style: TextStyle(color: AppColors.warning, fontSize: 13),
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

  Widget _buildCostRow(
    String label,
    String amount,
    String subtitle, {
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isHighlighted
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: isHighlighted ? 16 : 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.grey500, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isHighlighted ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitExtension,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: AppColors.grey400,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            : const Text(
                'Confirm Extension',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
