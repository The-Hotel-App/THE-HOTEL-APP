import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';

/// Reusable text field builder for setup forms
class SetupTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool required;

  const SetupTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
      ),
    );
  }
}

/// Number selector widget with increment/decrement buttons
class NumberSelector extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const NumberSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: value > min ? () => onChanged(value - 1) : null,
                    icon: const Icon(Icons.remove, size: 20),
                    color: AppColors.black,
                  ),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: value < max ? () => onChanged(value + 1) : null,
                    icon: const Icon(Icons.add, size: 20),
                    color: AppColors.black,
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

/// Password text field with visibility toggle
class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final IconData prefixIcon;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.isVisible,
    required this.onToggleVisibility,
    this.prefixIcon = Icons.lock,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
