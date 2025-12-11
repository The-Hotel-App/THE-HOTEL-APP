import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Pending Requests Page - For owners/managers to approve/reject join requests
class PendingRequestsPage extends ConsumerStatefulWidget {
  const PendingRequestsPage({super.key});

  @override
  ConsumerState<PendingRequestsPage> createState() =>
      _PendingRequestsPageState();
}

class _PendingRequestsPageState extends ConsumerState<PendingRequestsPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final hotelId = ref.read(selectedHotelIdProvider);
      if (hotelId == null) return;

      final client = SupabaseService.instance.client;
      final response = await client
          .from('join_requests')
          .select('''
            *,
            user_profiles:user_id (id, name, phone)
          ''')
          .eq('hotel_id', hotelId)
          .order('requested_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading requests: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load requests: $e')));
      }
    }
  }

  Future<void> _handleRequest(
    String requestId,
    String userId,
    String action,
    UserRole? role,
  ) async {
    if (action == 'approved' && role == null) {
      // Show role selection dialog
      final selectedRole = await _showRoleDialog();
      if (selectedRole == null) return;
      role = selectedRole;
    }

    setState(() => _isLoading = true);
    try {
      final hotelId = ref.read(selectedHotelIdProvider);
      final currentUserId = ref.read(currentUserProvider).valueOrNull?.id;
      if (hotelId == null || currentUserId == null) return;

      final client = SupabaseService.instance.client;

      // Update request status
      await client
          .from('join_requests')
          .update({
            'status': action,
            'processed_at': DateTime.now().toIso8601String(),
            'processed_by': currentUserId,
            'assigned_role': role?.dbValue,
          })
          .eq('id', requestId);

      // If approved, add to hotel_staff
      if (action == 'approved' && role != null) {
        await client.from('hotel_staff').insert({
          'hotel_id': hotelId,
          'user_id': userId,
          'role': role.dbValue,
          'is_active': true,
          'created_by': currentUserId,
        });
      }

      await _loadRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approved'
                  ? 'Request approved! User added as ${role?.displayName}'
                  : 'Request rejected',
            ),
            backgroundColor: action == 'approved'
                ? AppColors.success
                : AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling request: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process request: $e')),
        );
      }
    }
  }

  Future<UserRole?> _showRoleDialog() async {
    return showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values
              .where((r) => r != UserRole.owner) // Don't assign owner role
              .map(
                (role) => ListTile(
                  leading: Icon(_getRoleIcon(role)),
                  title: Text(role.displayName),
                  onTap: () => Navigator.pop(context, role),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.star;
      case UserRole.manager:
        return Icons.admin_panel_settings;
      case UserRole.staff:
        return Icons.person;
      case UserRole.kitchenManager:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests = _requests
        .where((r) => r['status'] == 'pending')
        .toList();
    final processedRequests = _requests
        .where((r) => r['status'] != 'pending')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Join Requests',
          style: TextStyle(color: AppColors.black),
        ),
        iconTheme: const IconThemeData(color: AppColors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendingRequests.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Pending (${pendingRequests.length})',
                    AppColors.warning,
                  ),
                  ...pendingRequests.map((r) => _buildRequestCard(r, true)),
                  const SizedBox(height: 24),
                ],
                if (processedRequests.isNotEmpty) ...[
                  _buildSectionHeader('Processed', AppColors.grey500),
                  ...processedRequests.map((r) => _buildRequestCard(r, false)),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          const Text(
            'No Join Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your hotel code and join code\nfor employees to request access',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, bool isPending) {
    final userProfile = request['user_profiles'] as Map<String, dynamic>?;
    final name = userProfile?['name'] as String? ?? 'Unknown';
    final phone = userProfile?['phone'] as String?;
    final status = request['status'] as String? ?? 'pending';
    final requestedAt = DateTime.tryParse(request['requested_at'] ?? '');
    final assignedRole = request['assigned_role'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPending
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : status == 'approved'
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: isPending
                        ? AppColors.warning
                        : status == 'approved'
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (phone != null)
                        Text(
                          phone,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'approved'
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status == 'approved'
                          ? assignedRole != null
                                ? 'Approved (${_formatRole(assignedRole)})'
                                : 'Approved'
                          : 'Rejected',
                      style: TextStyle(
                        color: status == 'approved'
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (requestedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Requested: ${_formatDateTime(requestedAt)}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleRequest(
                      request['id'] as String,
                      request['user_id'] as String,
                      'rejected',
                      null,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _handleRequest(
                      request['id'] as String,
                      request['user_id'] as String,
                      'approved',
                      null,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'staff':
        return 'Staff';
      case 'kitchen_manager':
        return 'Kitchen';
      default:
        return role;
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
