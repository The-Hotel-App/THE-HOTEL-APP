import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/hotel_setup/data/repositories/supabase_hotel_setup_repository.dart';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel_new.dart';
import 'package:rooms/src/features/settings/presentation/widgets/biometric_settings_section.dart';

class HotelSettingsPage extends ConsumerStatefulWidget {
  const HotelSettingsPage({super.key});

  @override
  ConsumerState<HotelSettingsPage> createState() => _HotelSettingsPageState();
}

class _HotelSettingsPageState extends ConsumerState<HotelSettingsPage> {
  Hotel? _hotel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHotel();
  }

  Future<void> _loadHotel() async {
    final currentHotel = ref.read(currentHotelProvider);
    if (currentHotel == null) {
      setState(() {
        _error = 'No hotel selected';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() => _isLoading = true);
      final repository = SupabaseHotelSetupRepository();
      final hotel = await repository.getHotel(currentHotel.hotelId);
      setState(() {
        _hotel = hotel;
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

  Future<void> _updateHotelField(String field, dynamic value) async {
    if (_hotel == null) return;

    try {
      final client = SupabaseService.instance.client;
      await client.from('hotels').update({field: value}).eq('id', _hotel!.id);

      // Refresh hotel data
      await _loadHotel();

      // Invalidate providers to refresh everywhere
      ref.invalidate(userHotelsProvider);
      ref.invalidate(currentHotelProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated successfully'),
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

  void _showEditDialog({
    required String title,
    required String field,
    required String currentValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: currentValue);

    CustomDialog.show(
      context: context,
      title: 'Edit $title',
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        autofocus: true,
      ),
      primaryButtonText: 'Save',
      onPrimaryPressed: () {
        Navigator.pop(context);
        _updateHotelField(field, controller.text.trim());
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Hotel Settings'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHotel,
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
            ElevatedButton(onPressed: _loadHotel, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_hotel == null) {
      return const Center(child: Text('Hotel not found'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Card
        _buildHeaderCard(),
        const SizedBox(height: 24),

        // Basic Information
        _buildSectionTitle('Basic Information'),
        const SizedBox(height: 12),
        _buildEditableCard(
          icon: Icons.hotel,
          title: 'Hotel Name',
          value: _hotel!.name,
          onTap: () => _showEditDialog(
            title: 'Hotel Name',
            field: 'name',
            currentValue: _hotel!.name,
          ),
        ),
        const SizedBox(height: 8),
        _buildEditableCard(
          icon: Icons.location_on,
          title: 'Address',
          value: _hotel!.address,
          onTap: () => _showEditDialog(
            title: 'Address',
            field: 'address',
            currentValue: _hotel!.address,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 24),

        // Contact Information
        _buildSectionTitle('Contact Information'),
        const SizedBox(height: 12),
        _buildEditableCard(
          icon: Icons.phone,
          title: 'Phone',
          value: _hotel!.phone ?? 'Not set',
          onTap: () => _showEditDialog(
            title: 'Phone',
            field: 'phone',
            currentValue: _hotel!.phone ?? '',
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 8),
        _buildEditableCard(
          icon: Icons.email,
          title: 'Email',
          value: _hotel!.email ?? 'Not set',
          onTap: () => _showEditDialog(
            title: 'Email',
            field: 'email',
            currentValue: _hotel!.email ?? '',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 24),

        // Property Details
        _buildSectionTitle('Property Details'),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.layers,
          title: 'Total Floors',
          value: '${_hotel!.totalFloors}',
        ),
        const SizedBox(height: 8),
        _buildInfoCard(
          icon: Icons.bed,
          title: 'Total Rooms',
          value: '${_hotel!.totalRooms}',
        ),
        const SizedBox(height: 24),

        // Quick Actions
        _buildSectionTitle('Room Management'),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.category,
          title: 'Room Types',
          subtitle: 'Manage room categories and pricing',
          color: AppColors.info,
          onTap: () => context.push('/room-types'),
        ),
        const SizedBox(height: 8),
        _buildActionCard(
          icon: Icons.meeting_room,
          title: 'Rooms',
          subtitle: 'Add, edit, or remove rooms',
          color: AppColors.info,
          onTap: () => context.push('/rooms-management'),
        ),
        const SizedBox(height: 24),

        // Security Settings (Requirement 6.1)
        _buildSectionTitle('Security'),
        const SizedBox(height: 12),
        const BiometricSettingsSection(),
        const SizedBox(height: 24),

        // TODO: Daily Reports Section
        // ============================================================
        // DAILY REPORTS FEATURE (TO BE IMPLEMENTED)
        // ============================================================
        //
        // Feature: Send daily summary report to owner at a customizable time
        //
        // Report Contents:
        // - Check-ins for the day
        // - Check-outs for the day
        // - Room status changes (with timestamps and who made them)
        // - Revenue summary (if applicable)
        // - Occupancy statistics
        // - Any emergency/maintenance flags
        //
        // Implementation:
        // 1. Add a "Notifications" section in this settings page with:
        //    - Time picker for report delivery time (e.g., 9:00 PM)
        //    - Toggle to enable/disable daily reports
        //    - Store settings in hotel_settings or user_preferences table
        //
        // 2. Backend (Supabase):
        //    - Create Edge Function: send-daily-report
        //    - Use pg_cron extension to schedule the function
        //    - Query all hotels with daily reports enabled
        //    - For each hotel, gather day's activities and format report
        //    - Send via push notification and/or email to owner
        //
        // 3. Database Schema:
        //    - Add columns to hotels table or create hotel_settings:
        //      * daily_report_enabled: boolean
        //      * daily_report_time: time (e.g., '21:00:00')
        //      * daily_report_timezone: text (e.g., 'Asia/Kolkata')
        //
        // 4. CRON Setup (in Supabase SQL):
        //    SELECT cron.schedule(
        //      'send-daily-reports',
        //      '0 * * * *', -- Run every hour, check which hotels need reports
        //      $$SELECT net.http_post(
        //        url := 'https://<project>.supabase.co/functions/v1/send-daily-report',
        //        headers := '{"Authorization": "Bearer <anon-key>"}'::jsonb
        //      );$$
        //    );
        // ============================================================
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.black, AppColors.grey700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business, color: AppColors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hotel?.name ?? 'Hotel',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_hotel?.totalRooms ?? 0} Rooms • ${_hotel?.totalFloors ?? 0} Floors',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEditableCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.warning, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, color: AppColors.grey600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.edit, size: 18, color: AppColors.grey600),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.success, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, color: AppColors.grey600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }
}
