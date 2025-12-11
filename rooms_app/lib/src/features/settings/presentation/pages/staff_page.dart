import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/settings/data/repositories/staff_repository.dart';

class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});

  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends ConsumerState<StaffPage> {
  bool _isLoading = true;
  String? _error;
  List<StaffMember> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final hotel = ref.read(currentHotelProvider);
    if (hotel == null) {
      setState(() {
        _error = 'No hotel selected';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() => _isLoading = true);
      final repository = ref.read(staffRepositoryProvider);
      final staff = await repository.getStaff(hotel.hotelId);

      setState(() {
        _staff = staff;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadStaff, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          _buildHeaderCard(),
          const SizedBox(height: 20),

          // Staff List
          if (_staff.isEmpty)
            _buildEmptyState()
          else
            ..._staff.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStaffCard(member),
              ),
            ),

          const SizedBox(height: 20),

          // Add Staff Button
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.createStaff),
            icon: const Icon(Icons.person_add),
            label: const Text('Add New Staff'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.grey700.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups, color: AppColors.grey700, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_staff.length} Staff Members',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage hotel staff and permissions',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          const Text(
            'No Staff Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add staff members to your hotel',
            style: TextStyle(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(StaffMember member) {
    final roleColor = _getRoleColor(member.role);
    final roleIcon = _getRoleIcon(member.role);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(roleIcon, color: roleColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!member.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey400,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.role.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (member.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    member.phone!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.grey600),
            onSelected: (value) => _handleMenuAction(value, member),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: member.isActive ? 'deactivate' : 'activate',
                child: Row(
                  children: [
                    Icon(
                      member.isActive ? Icons.block : Icons.check_circle,
                      size: 20,
                      color: member.isActive
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(member.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Remove'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return AppColors.grey800;
      case UserRole.manager:
        return AppColors.info;
      case UserRole.staff:
        return AppColors.success;
      case UserRole.kitchenManager:
        return AppColors.warning;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.staff:
        return Icons.person;
      case UserRole.kitchenManager:
        return Icons.restaurant;
    }
  }

  Future<void> _handleMenuAction(String action, StaffMember member) async {
    switch (action) {
      case 'activate':
      case 'deactivate':
        try {
          final repository = ref.read(staffRepositoryProvider);
          await repository.toggleStaffActive(member.id, action == 'activate');
          await _loadStaff();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Staff ${action == 'activate' ? 'activated' : 'deactivated'}',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
        break;
      case 'remove':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove Staff?'),
            content: Text('Remove ${member.name} from this hotel?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            final repository = ref.read(staffRepositoryProvider);
            await repository.removeStaff(member.id);
            await _loadStaff();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Staff removed'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
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
        break;
    }
  }
}
