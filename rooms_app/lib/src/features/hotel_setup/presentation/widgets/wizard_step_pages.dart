import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel.dart';
import 'package:rooms/src/features/hotel_setup/presentation/widgets/floor_range_input.dart';
import 'package:rooms/src/features/hotel_setup/presentation/widgets/setup_form_widgets.dart';

/// Owner Registration Page - Step 1 of the wizard
class OwnerRegistrationStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const OwnerRegistrationStep({
    super.key,
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👤 Owner Profile',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile to manage your hotel',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          SetupTextField(
            controller: nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person,
            required: true,
          ),
          const SizedBox(height: 16),
          SetupTextField(
            controller: phoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            required: true,
          ),
        ],
      ),
    );
  }
}

/// Hotel Profile Page - Step 2 of the wizard
class HotelProfileStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  const HotelProfileStep({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏨 Hotel Information',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start with basic details about your hotel',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          SetupTextField(
            controller: nameController,
            label: 'Hotel Name',
            hint: 'Enter hotel name',
            icon: Icons.business,
            required: true,
          ),
          const SizedBox(height: 16),
          SetupTextField(
            controller: addressController,
            label: 'Address',
            hint: 'Enter full address',
            icon: Icons.location_on,
            maxLines: 2,
            required: true,
          ),
          const SizedBox(height: 16),
          SetupTextField(
            controller: phoneController,
            label: 'Phone',
            hint: 'Enter phone number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SetupTextField(
            controller: emailController,
            label: 'Email',
            hint: 'Enter email address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }
}

/// Floors & Rooms Page - Step 3 of the wizard
class FloorsRoomsStep extends StatelessWidget {
  final int totalFloors;
  final int totalRooms;
  final ValueChanged<int> onFloorsChanged;
  final Map<int, TextEditingController> startRoomControllers;
  final Map<int, TextEditingController> endRoomControllers;
  final Map<int, FocusNode>? startRoomFocusNodes;
  final Map<int, FocusNode>? endRoomFocusNodes;
  final VoidCallback onRoomRangeChanged;
  final void Function(int floor) onRoomRangeSubmitted;
  final int Function(int floor) getRoomCount;

  const FloorsRoomsStep({
    super.key,
    required this.totalFloors,
    required this.totalRooms,
    required this.onFloorsChanged,
    required this.startRoomControllers,
    required this.endRoomControllers,
    this.startRoomFocusNodes,
    this.endRoomFocusNodes,
    required this.onRoomRangeChanged,
    required this.onRoomRangeSubmitted,
    required this.getRoomCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏢 Floors & Rooms',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define room ranges for each floor',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalRooms > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$totalRooms rooms',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          NumberSelector(
            label: 'Total Floors',
            value: totalFloors,
            onChanged: onFloorsChanged,
            min: 1,
            max: 20,
          ),
          const SizedBox(height: 16),
          ...List.generate(totalFloors, (index) {
            final floor = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloorRangeInput(
                floor: floor,
                startController: startRoomControllers[floor]!,
                endController: endRoomControllers[floor]!,
                startFocusNode: startRoomFocusNodes?[floor],
                endFocusNode: endRoomFocusNodes?[floor],
                onChanged: onRoomRangeChanged,
                onSubmitted: () => onRoomRangeSubmitted(floor),
                roomCount: getRoomCount(floor),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Room Types Page - Step 4 of the wizard
class RoomTypesStep extends StatelessWidget {
  final List<RoomType> roomTypes;
  final VoidCallback onAddRoomType;
  final void Function(int index) onRemoveRoomType;

  const RoomTypesStep({
    super.key,
    required this.roomTypes,
    required this.onAddRoomType,
    required this.onRemoveRoomType,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛏️ Room Types',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Define your room categories, pricing, and max occupancy',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildInfoBanner(context),
          const SizedBox(height: 24),
          if (roomTypes.isEmpty)
            _buildEmptyRoomTypesCard(context)
          else
            ...roomTypes.asMap().entries.map(
              (e) => _buildRoomTypeCard(context, e.key, e.value),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAddRoomType,
            icon: const Icon(Icons.add),
            label: const Text('Add Room Type'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.black),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can always customize room types, prices, and assignments from Settings → Room Types later.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRoomTypesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.hotel, size: 48, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No room types defined yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add room types now, or skip this step and configure them later from Settings',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap "Complete Setup" to skip, or add your first room type below.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeCard(
    BuildContext context,
    int index,
    RoomType roomType,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.black,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          roomType.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '₹${roomType.basePrice.toStringAsFixed(0)}/night • ${roomType.maxOccupancy} guests',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: AppColors.error),
          onPressed: () => onRemoveRoomType(index),
        ),
      ),
    );
  }
}

/// Wizard Navigation Buttons
class WizardNavigationButtons extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  const WizardNavigationButtons({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
    required this.onNext,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.black),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: currentPage == totalPages - 1 ? onComplete : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                currentPage == totalPages - 1 ? 'Complete Setup' : 'Continue',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wizard Progress Indicator
class WizardProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const WizardProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: (currentPage + 1) / totalPages,
          backgroundColor: AppColors.grey200,
          valueColor: const AlwaysStoppedAnimation(AppColors.black),
          minHeight: 8,
        ),
      ),
    );
  }
}
