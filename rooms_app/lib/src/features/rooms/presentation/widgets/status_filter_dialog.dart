import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Dialog for filtering rooms by status
class StatusFilterDialog extends ConsumerStatefulWidget {
  const StatusFilterDialog({super.key});

  @override
  ConsumerState<StatusFilterDialog> createState() => _StatusFilterDialogState();
}

class _StatusFilterDialogState extends ConsumerState<StatusFilterDialog> {
  late Set<RoomStatus> localSelected;

  @override
  void initState() {
    super.initState();
    localSelected = Set.from(ref.read(selectedStatusFilterProvider));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter by Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filter options
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ...RoomStatus.values.map((status) {
                  final isSelected = localSelected.contains(status);
                  final statusColor = RoomStatusColors.getColor(status.name);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          localSelected.add(status);
                        } else {
                          localSelected.remove(status);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(status.displayName),
                      ],
                    ),
                    activeColor: statusColor,
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() => localSelected.clear());
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      ref.read(selectedStatusFilterProvider.notifier).state =
                          localSelected;
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
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
