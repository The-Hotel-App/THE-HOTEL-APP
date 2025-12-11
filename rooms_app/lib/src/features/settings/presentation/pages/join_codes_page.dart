import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Join Codes Management Page - For owners/managers to create and manage join codes
class JoinCodesPage extends ConsumerStatefulWidget {
  const JoinCodesPage({super.key});

  @override
  ConsumerState<JoinCodesPage> createState() => _JoinCodesPageState();
}

class _JoinCodesPageState extends ConsumerState<JoinCodesPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _joinCodes = [];

  @override
  void initState() {
    super.initState();
    _loadJoinCodes();
  }

  Future<void> _loadJoinCodes() async {
    setState(() => _isLoading = true);
    try {
      final hotelId = ref.read(selectedHotelIdProvider);
      if (hotelId == null) return;

      final client = SupabaseService.instance.client;
      final response = await client
          .from('join_codes')
          .select()
          .eq('hotel_id', hotelId)
          .order('created_at', ascending: false);

      setState(() {
        _joinCodes = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading join codes: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load join codes: $e')),
        );
      }
    }
  }

  Future<void> _generateJoinCode() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _GenerateJoinCodeDialog(),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final hotelId = ref.read(selectedHotelIdProvider);
        final userId = ref.read(currentUserProvider).valueOrNull?.id;
        if (hotelId == null || userId == null) return;

        final client = SupabaseService.instance.client;
        await client.from('join_codes').insert({
          'hotel_id': hotelId,
          'code': result['code'],
          'expires_at': result['expiresAt'],
          'max_uses': result['maxUses'],
          'created_by': userId,
        });

        await _loadJoinCodes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Join code created successfully!')),
          );
        }
      } catch (e) {
        debugPrint('Error creating join code: $e');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create join code: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleJoinCode(String codeId, bool isActive) async {
    try {
      final client = SupabaseService.instance.client;
      await client
          .from('join_codes')
          .update({'is_active': !isActive})
          .eq('id', codeId);
      await _loadJoinCodes();
    } catch (e) {
      debugPrint('Error toggling join code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update join code: $e')),
        );
      }
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Join Codes',
          style: TextStyle(color: AppColors.black),
        ),
        iconTheme: const IconThemeData(color: AppColors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJoinCodes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _joinCodes.isEmpty
          ? _buildEmptyState()
          : _buildCodesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateJoinCode,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Generate Code'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          const Text(
            'No Join Codes Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a join code to let employees join your hotel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateJoinCode,
            icon: const Icon(Icons.add),
            label: const Text('Generate Join Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _joinCodes.length,
      itemBuilder: (context, index) {
        final code = _joinCodes[index];
        final isActive = code['is_active'] as bool? ?? true;
        final expiresAt = DateTime.tryParse(code['expires_at'] ?? '');
        final isExpired =
            expiresAt != null && expiresAt.isBefore(DateTime.now());
        final maxUses = code['max_uses'] as int? ?? 10;
        final currentUses = code['current_uses'] as int? ?? 0;
        final isMaxedOut = currentUses >= maxUses;

        final isUsable = isActive && !isExpired && !isMaxedOut;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUsable
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.grey200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.key,
                color: isUsable ? AppColors.success : AppColors.grey500,
              ),
            ),
            title: Row(
              children: [
                Text(
                  code['code'] as String? ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyCode(code['code'] as String? ?? ''),
                  tooltip: 'Copy code',
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTag(
                      '$currentUses / $maxUses uses',
                      isMaxedOut ? AppColors.error : AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    if (expiresAt != null)
                      _buildTag(
                        isExpired
                            ? 'Expired'
                            : 'Expires ${_formatDate(expiresAt)}',
                        isExpired ? AppColors.error : AppColors.grey600,
                      ),
                  ],
                ),
              ],
            ),
            trailing: Switch(
              value: isActive,
              onChanged: (value) =>
                  _toggleJoinCode(code['id'] as String, isActive),
              activeColor: AppColors.success,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays > 1) return '${diff.inDays}d';
    if (diff.inHours > 1) return '${diff.inHours}h';
    return 'soon';
  }
}

/// Dialog to generate a new join code
class _GenerateJoinCodeDialog extends StatefulWidget {
  const _GenerateJoinCodeDialog();

  @override
  State<_GenerateJoinCodeDialog> createState() =>
      _GenerateJoinCodeDialogState();
}

class _GenerateJoinCodeDialogState extends State<_GenerateJoinCodeDialog> {
  final _codeController = TextEditingController();
  int _maxUses = 10;
  int _expiryDays = 7;

  @override
  void initState() {
    super.initState();
    _generateRandomCode();
  }

  void _generateRandomCode() {
    final code = 'JOIN${DateTime.now().millisecondsSinceEpoch % 10000}';
    _codeController.text = code;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Join Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Join Code',
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generateRandomCode,
                tooltip: 'Generate new code',
              ),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          Text(
            'Maximum Uses: $_maxUses',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _maxUses.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: _maxUses.toString(),
            onChanged: (value) => setState(() => _maxUses = value.toInt()),
          ),
          const SizedBox(height: 8),
          Text(
            'Expires in: $_expiryDays days',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _expiryDays.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            label: '$_expiryDays days',
            onChanged: (value) => setState(() => _expiryDays = value.toInt()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_codeController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a code')),
              );
              return;
            }
            Navigator.pop(context, {
              'code': _codeController.text.trim().toUpperCase(),
              'maxUses': _maxUses,
              'expiresAt': DateTime.now()
                  .add(Duration(days: _expiryDays))
                  .toIso8601String(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.black,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
