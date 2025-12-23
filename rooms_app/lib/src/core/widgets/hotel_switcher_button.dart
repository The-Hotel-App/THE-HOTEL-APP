import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Hotel Switcher Button - Shows current hotel and allows switching
/// Only visible when user has access to multiple hotels
class HotelSwitcherButton extends ConsumerWidget {
  const HotelSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(userHotelsProvider);
    final currentHotel = ref.watch(currentHotelProvider);

    return hotelsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (hotels) {
        // Only show if user has multiple hotels
        if (hotels.length <= 1) return const SizedBox.shrink();

        return InkWell(
          onTap: () => _showHotelSwitcher(context, ref, hotels, currentHotel),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hotel, size: 18),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    currentHotel?.hotelName ?? 'Select Hotel',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHotelSwitcher(
    BuildContext context,
    WidgetRef ref,
    List<UserHotel> hotels,
    UserHotel? currentHotel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _HotelSwitcherSheet(
        hotels: hotels,
        currentHotelId: currentHotel?.hotelId,
        onSelect: (hotel) {
          Navigator.pop(context);
          if (hotel.hotelId != currentHotel?.hotelId) {
            ref.read(selectedHotelIdProvider.notifier).state = hotel.hotelId;
            // Invalidate providers to refresh data
            ref.invalidate(userHotelsProvider);
            ref.invalidate(currentHotelProvider);
          }
        },
      ),
    );
  }
}

/// Hotel Switcher Bottom Sheet
class _HotelSwitcherSheet extends StatelessWidget {
  final List<UserHotel> hotels;
  final String? currentHotelId;
  final void Function(UserHotel hotel) onSelect;

  const _HotelSwitcherSheet({
    required this.hotels,
    required this.currentHotelId,
    required this.onSelect,
  });

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return AppColors.warning;
      case UserRole.manager:
        return AppColors.info;
      case UserRole.staff:
        return AppColors.success;
      case UserRole.kitchenManager:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: AppColors.black),
                  const SizedBox(width: 12),
                  Text(
                    'Switch Hotel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Hotel list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: hotels.length,
                itemBuilder: (context, index) {
                  final hotel = hotels[index];
                  final isSelected = hotel.hotelId == currentHotelId;
                  final roleColor = _getRoleColor(hotel.role);
                  
                  return ListTile(
                    onTap: () => onSelect(hotel),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.hotel,
                        color: isSelected ? AppColors.success : AppColors.grey600,
                      ),
                    ),
                    title: Text(
                      hotel.hotelName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.success : AppColors.black,
                      ),
                    ),
                    subtitle: Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hotel.role.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.success)
                        : const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey400),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
