import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/settings/data/repositories/staff_repository.dart';

/// Header card showing staff count summary
class StaffHeaderCard extends StatelessWidget {
  final int staffCount;

  const StaffHeaderCard({super.key, required this.staffCount});

  @override
  Widget build(BuildContext context) {
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
                  '$staffCount Staff Members',
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
}

/// Empty state when no staff exists
class StaffEmptyState extends StatelessWidget {
  const StaffEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// Card displaying a single staff member
class StaffMemberCard extends StatelessWidget {
  final StaffMember member;
  final void Function(String action, StaffMember member) onMenuAction;
  final bool isCurrentUser;

  const StaffMemberCard({
    super.key,
    required this.member,
    required this.onMenuAction,
    this.isCurrentUser = false,
  });

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

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(member.role);
    final roleIcon = _getRoleIcon(member.role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: roleColor, width: 3)),
      ),
      child: Row(
        children: [
          // Compact role icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(roleIcon, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name row with inactive badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!member.isActive)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                // Role badge - compact
                Text(
                  member.role.displayName,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Show "You" badge, "Owner" badge, or menu options
          // Owners cannot be deactivated/removed by anyone
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (member.role == UserRole.owner)
            // Owners cannot be modified by other users
            const SizedBox.shrink()
          else
            IconButton(
              icon: const Icon(Icons.more_horiz, color: AppColors.grey600),
              onPressed: () => _showActionsSheet(context),
            ),
        ],
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              const SizedBox(height: 8),

              // Edit option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.black,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onMenuAction('edit', member);
                },
              ),

              // Activate/Deactivate option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        (member.isActive
                                ? AppColors.warning
                                : AppColors.success)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    member.isActive ? Icons.block : Icons.check_circle,
                    color: member.isActive
                        ? AppColors.warning
                        : AppColors.success,
                    size: 20,
                  ),
                ),
                title: Text(
                  member.isActive ? 'Deactivate' : 'Activate',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onMenuAction(
                    member.isActive ? 'deactivate' : 'activate',
                    member,
                  );
                },
              ),

              // Remove option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Remove',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onMenuAction('remove', member);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation dialog for removing staff
class RemoveStaffDialog extends StatelessWidget {
  final String memberName;

  const RemoveStaffDialog({super.key, required this.memberName});

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Remove Staff?',
      icon: Icons.person_remove,
      type: CustomDialogType.destructive,
      content: Text(
        'Remove $memberName from this hotel?\n\n'
        'This will permanently delete their account if they only work at this hotel.',
      ),
      primaryButtonText: 'Remove',
      onPrimaryPressed: () => Navigator.pop(context, true),
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context, false),
    );
  }
}

/// Edit staff bottom sheet dialog - Name and Role only
class EditStaffSheet extends StatefulWidget {
  final StaffMember member;
  final Future<void> Function(String name, UserRole role) onSave;

  const EditStaffSheet({super.key, required this.member, required this.onSave});

  @override
  State<EditStaffSheet> createState() => _EditStaffSheetState();
}

class _EditStaffSheetState extends State<EditStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late UserRole _selectedRole;
  bool _isLoading = false;

  // Available roles (excluding owner - owners can't be created/edited here)
  static const _editableRoles = [
    UserRole.manager,
    UserRole.staff,
    UserRole.kitchenManager,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _selectedRole = widget.member.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onSave(_nameController.text.trim(), _selectedRole);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    const Icon(Icons.edit, color: AppColors.black),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Staff',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 16),

                // Role selection
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _editableRoles.map((role) {
                    final isSelected = _selectedRole == role;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRole = role),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.black
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.black
                                : AppColors.grey300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          role.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.grey700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
