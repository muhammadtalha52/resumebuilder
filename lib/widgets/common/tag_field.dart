import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class TagField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final List<String> tags;
  final TextEditingController controller;
  final Function(String) onAdd;
  final Function(String) onRemove;
  final String? errorText;
  final VoidCallback? onClearError;

  const TagField({
    super.key,
    required this.label,
    required this.isRequired,
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    this.errorText,
    this.onClearError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            // Clear error when user starts typing
            if (errorText != null && value.isNotEmpty && onClearError != null) {
              onClearError!();
            }
          },
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              onAdd(value);
            }
          },
          decoration: InputDecoration(
            hintText: 'Add tags...',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 16),
            suffixIcon: IconButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  onAdd(text);
                }
              },
              icon: const Icon(
                Icons.add_circle,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.inputBorderFocused,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        // Error message
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
        // Tags display (outside the input field)
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((tag) => _buildTag(context, tag, onRemove))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(
    BuildContext context,
    String tag,
    Function(String) onRemove,
  ) {
    return Tooltip(
      message: tag, // Show full text in tooltip
      waitDuration: const Duration(milliseconds: 500),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200), // Limit max width
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEBEEFF), // Surface color
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF7777F8),
            width: 1.5,
          ), // Border color
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () {
                  // Show full text in a dialog when tapped
                  _showFullTagDialog(context, tag);
                },
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => onRemove(tag),
              child: const Icon(Icons.close, size: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullTagDialog(BuildContext context, String tag) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Full Tag Text'),
          content: SingleChildScrollView(
            child: Text(tag, style: const TextStyle(fontSize: 16)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
