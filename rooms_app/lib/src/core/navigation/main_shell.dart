import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/bookings/presentation/pages/bookings_page.dart';
import 'package:rooms/src/features/customers/presentation/pages/customers_page.dart';
import 'package:rooms/src/features/rooms/presentation/pages/rooms_page.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';
import 'package:rooms/src/features/settings/presentation/pages/more_page.dart';
import 'package:rooms/src/core/navigation/dashboard_tab.dart';

/// Tracks the current tab index in the main shell
final mainShellTabProvider = StateProvider<int>((ref) => 0);

/// Main shell with bottom navigation for the hotel app.
/// Shows 5 tabs: Dashboard, Rooms, Bookings, Guests, More
/// Bookings and Guests are only visible for Owner and Manager roles.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(mainShellTabProvider);
    final hotel = ref.watch(currentHotelProvider);
    final role = hotel?.role ?? UserRole.staff;

    // Build tabs based on role
    final tabs = _buildTabs(role);
    final currentIndex = tabIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: tabs.map((tab) => tab.page).toList(),
      ),
      bottomNavigationBar: _buildBottomNav(tabs, currentIndex, role),
    );
  }

  List<NavTab> _buildTabs(UserRole role) {
    final isOwnerOrManager = role == UserRole.owner || role == UserRole.manager;

    return [
      // Dashboard - Always visible
      NavTab(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        page: const DashboardTab(),
      ),
      // Rooms - Always visible
      NavTab(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'Rooms',
        page: const RoomsTabContent(),
      ),
      // Bookings - Owner/Manager only
      if (isOwnerOrManager)
        NavTab(
          icon: Icons.book_online_outlined,
          activeIcon: Icons.book_online,
          label: 'Bookings',
          page: const BookingsTabContent(),
        ),
      // Guests - Owner/Manager only
      if (isOwnerOrManager)
        NavTab(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'Guests',
          page: const GuestsTabContent(),
        ),
      // More - Always visible
      NavTab(
        icon: Icons.more_horiz,
        activeIcon: Icons.more_horiz,
        label: 'More',
        page: const MorePage(),
      ),
    ];
  }

  Widget _buildBottomNav(List<NavTab> tabs, int currentIndex, UserRole role) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    // Reset floor selection when Rooms tab is tapped
                    if (tabs[index].label == 'Rooms') {
                      ref.read(selectedFloorProvider.notifier).state = null;
                    }
                    ref.read(mainShellTabProvider.notifier).state = index;
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.black.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isSelected ? tab.activeIcon : tab.icon,
                            color: isSelected
                                ? AppColors.black
                                : AppColors.grey500,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.black
                                : AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Data class for navigation tabs
class NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;

  const NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });
}

/// Rooms tab content wrapper - removes the back button behavior
class RoomsTabContent extends ConsumerWidget {
  const RoomsTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RoomsPage(embedded: true);
  }
}

/// Bookings tab content wrapper
class BookingsTabContent extends ConsumerWidget {
  const BookingsTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const BookingsPage(embedded: true);
  }
}

/// Guests tab content wrapper
class GuestsTabContent extends ConsumerWidget {
  const GuestsTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomersPage(embedded: true);
  }
}
