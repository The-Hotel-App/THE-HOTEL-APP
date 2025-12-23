import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/settings/data/repositories/staff_repository.dart';
import 'package:rooms/src/features/settings/presentation/widgets/staff_widgets.dart';

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
          StaffHeaderCard(staffCount: _staff.length),
          const SizedBox(height: 20),

          // Staff List
          if (_staff.isEmpty)
            const StaffEmptyState()
          else
            ..._staff.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StaffMemberCard(
                  member: member,
                  onMenuAction: _handleMenuAction,
                ),
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

  Future<void> _handleMenuAction(String action, StaffMember member) async {
    switch (action) {
      case 'activate':
      case 'deactivate':
        await _toggleStaffActive(member, action == 'activate');
        break;
      case 'remove':
        await _removeStaff(member);
        break;
    }
  }

  Future<void> _toggleStaffActive(StaffMember member, bool activate) async {
    try {
      final repository = ref.read(staffRepositoryProvider);
      await repository.toggleStaffActive(member.id, activate);
      await _loadStaff();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff ${activate ? 'activated' : 'deactivated'}'),
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

  Future<void> _removeStaff(StaffMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => RemoveStaffDialog(memberName: member.name),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(staffRepositoryProvider);
        final hotel = ref.read(currentHotelProvider);
        if (hotel == null) {
          throw Exception('No hotel selected');
        }
        await repository.removeStaff(member.id, hotel.hotelId);
        await _loadStaff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff removed completely'),
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
  }
}
