import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';

/// Widget for inputting room range for a single floor
class FloorRangeInput extends StatelessWidget {
  final int floor;
  final TextEditingController startController;
  final TextEditingController endController;
  final FocusNode? startFocusNode;
  final FocusNode? endFocusNode;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;
  final int roomCount;

  const FloorRangeInput({
    super.key,
    required this.floor,
    required this.startController,
    required this.endController,
    this.startFocusNode,
    this.endFocusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.roomCount,
  });

  String get _defaultStartRoom => '${floor * 100 + 1}';
  String get _defaultEndRoom => '${floor * 100 + 10}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Floor $floor',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    focusNode: startFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: _defaultStartRoom,
                    ),
                    onChanged: (_) => onChanged(),
                    onSubmitted: (_) => onSubmitted(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '—',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: endController,
                    focusNode: endFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: _defaultEndRoom,
                    ),
                    onChanged: (_) => onChanged(),
                    onSubmitted: (_) => onSubmitted(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 65,
            child: Text(
              '$roomCount rooms',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
