import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/add_staff_sheet.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
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
        actions: const [],
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
          // Staff List grouped by role
          if (_staff.isEmpty)
            const StaffEmptyState()
          else
            ..._buildGroupedStaffList(),

          const SizedBox(height: 20),

          // Add Staff Button - shows options bottom sheet
          ElevatedButton.icon(
            onPressed: () => AddStaffSheet.show(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Staff'),
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

  /// Build staff list grouped by role with section headers
  List<Widget> _buildGroupedStaffList() {
    final currentUser = ref.read(currentUserProvider).valueOrNull;

    // Group staff by role
    final owners = _staff.where((s) => s.role == UserRole.owner).toList();
    final managers = _staff.where((s) => s.role == UserRole.manager).toList();
    final staffMembers = _staff.where((s) => s.role == UserRole.staff).toList();
    final kitchenManagers = _staff
        .where((s) => s.role == UserRole.kitchenManager)
        .toList();

    final widgets = <Widget>[];

    void addSection(String title, List<StaffMember> members, Color color) {
      if (members.isEmpty) return;

      // Section header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: AppColors.grey200)),
            ],
          ),
        ),
      );

      // Staff cards in this section
      for (final member in members) {
        final isCurrentUser = currentUser?.id == member.userId;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StaffMemberCard(
              member: member,
              onMenuAction: _handleMenuAction,
              isCurrentUser: isCurrentUser,
            ),
          ),
        );
      }
    }

    // Add sections in order: Owners → Managers → Staff → Kitchen
    addSection('Owners', owners, AppColors.grey800);
    addSection('Managers', managers, AppColors.info);
    addSection('Staff', staffMembers, AppColors.success);
    addSection('Kitchen', kitchenManagers, AppColors.warning);

    return widgets;
  }

  Future<void> _handleMenuAction(String action, StaffMember member) async {
    switch (action) {
      case 'edit':
        await _editStaff(member);
        break;
      case 'activate':
      case 'deactivate':
        await _toggleStaffActive(member, action == 'activate');
        break;
      case 'remove':
        await _removeStaff(member);
        break;
    }
  }

  Future<void> _editStaff(StaffMember member) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditStaffSheet(
        member: member,
        onSave: (name, role) async {
          final repository = ref.read(staffRepositoryProvider);
          await repository.updateStaff(
            staffId: member.id,
            userId: member.userId,
            name: name,
            role: role,
          );
        },
      ),
    );

    if (result == true) {
      await _loadStaff();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
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
