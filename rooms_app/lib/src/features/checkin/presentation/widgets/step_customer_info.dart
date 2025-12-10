import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/checkin/presentation/providers/checkin_providers.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Step 1: Customer Information
class StepCustomerInfo extends ConsumerStatefulWidget {
  final Room room;
  final VoidCallback onNext;

  const StepCustomerInfo({super.key, required this.room, required this.onNext});

  @override
  ConsumerState<StepCustomerInfo> createState() => _StepCustomerInfoState();
}

class _StepCustomerInfoState extends ConsumerState<StepCustomerInfo> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();

  Gender _selectedGender = Gender.male;
  IdType _selectedIdType = IdType.aadhar;
  int _guestCount = 1;
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('Guest Details', Icons.person),
            const SizedBox(height: 12),
            _buildNameField(),
            const SizedBox(height: 12),
            _buildPhoneField(),
            const SizedBox(height: 12),
            _buildGenderSelector(),
            const SizedBox(height: 20),

            _buildSectionTitle('ID Verification', Icons.badge),
            const SizedBox(height: 12),
            _buildIdTypeSelector(),
            const SizedBox(height: 12),
            _buildIdNumberField(),
            const SizedBox(height: 20),

            _buildSectionTitle('Stay Details', Icons.calendar_today),
            const SizedBox(height: 12),
            _buildGuestCountSelector(),
            const SizedBox(height: 12),
            _buildDateSelectors(),
            const SizedBox(height: 32),

            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.roomFree.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.roomFree, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.roomFree,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.room.roomNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.roomType,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${widget.room.pricePerNight.toStringAsFixed(0)}/night • Max ${widget.room.maxOccupancy} guests',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: _inputDecoration('Guest Name', Icons.person_outline),
      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: _inputDecoration('Phone Number', Icons.phone),
      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: Gender.values.map((gender) {
        final isSelected = _selectedGender == gender;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildSelectionChip(
              label: gender.displayName,
              icon: gender == Gender.male
                  ? Icons.male
                  : (gender == Gender.female ? Icons.female : Icons.person),
              isSelected: isSelected,
              onTap: () => setState(() => _selectedGender = gender),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIdTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IdType.values.map((type) {
        final isSelected = _selectedIdType == type;
        return _buildSelectionChip(
          label: type.displayName,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedIdType = type),
          compact: true,
        );
      }).toList(),
    );
  }

  Widget _buildIdNumberField() {
    return TextFormField(
      controller: _idNumberController,
      decoration: _inputDecoration('ID Number', Icons.badge_outlined),
      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildGuestCountSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: AppColors.black),
          const SizedBox(width: 12),
          const Text('Guests', style: TextStyle(fontSize: 16)),
          const Spacer(),
          IconButton(
            onPressed: _guestCount > 1
                ? () => setState(() => _guestCount--)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.black,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$_guestCount',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: _guestCount < widget.room.maxOccupancy
                ? () => setState(() => _guestCount++)
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectors() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            'Check In',
            _checkIn,
            (d) => setState(() => _checkIn = d),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateField(
            'Check Out',
            _checkOut,
            (d) => setState(() => _checkOut = d),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 20 : 12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(compact ? 20 : 12),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.white : AppColors.black,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleNext,
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
              'Next: Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.black, width: 2),
      ),
    );
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;

    // Create customer and update state
    final customer = Customer(
      id: 'cust-${DateTime.now().millisecondsSinceEpoch}',
      hotelId: 'hotel-001',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _selectedGender,
      idType: _selectedIdType,
      idNumber: _idNumberController.text.trim(),
      createdAt: DateTime.now(),
    );

    ref.read(checkinStateProvider.notifier).setCustomer(customer);
    ref.read(checkinStateProvider.notifier).setGuestCount(_guestCount);
    ref.read(checkinStateProvider.notifier).setDates(_checkIn, _checkOut);

    widget.onNext();
  }
}
