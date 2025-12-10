import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';

class HotelSettingsPage extends StatelessWidget {
  const HotelSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Hotel Settings'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
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
                  child: Icon(
                    Icons.business,
                    color: AppColors.grey700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hotel Configuration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage hotel details and preferences',
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
          ),
          const SizedBox(height: 20),

          // Settings Sections
          _buildSectionTitle('Basic Information'),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.hotel,
            title: 'Hotel Name',
            subtitle: 'Update your hotel name',
            color: AppColors.black,
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.location_on,
            title: 'Address',
            subtitle: 'Update hotel address',
            color: AppColors.black,
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.phone,
            title: 'Contact Information',
            subtitle: 'Phone and email details',
            color: AppColors.black,
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Room Configuration'),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.meeting_room,
            title: 'Room Types',
            subtitle: 'Manage room categories',
            color: AppColors.info,
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.attach_money,
            title: 'Pricing',
            subtitle: 'Default room rates',
            color: AppColors.info,
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Business Settings'),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.access_time,
            title: 'Check-in/Check-out Times',
            subtitle: 'Set standard timings',
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.policy,
            title: 'Policies',
            subtitle: 'Cancellation and refund policies',
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.receipt_long,
            title: 'Tax Settings',
            subtitle: 'Configure tax rates',
            color: AppColors.success,
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

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
        trailing: Icon(Icons.chevron_right, color: AppColors.grey600),
        onTap: () {
          // TODO: Navigate to specific setting
        },
      ),
    );
  }
}
