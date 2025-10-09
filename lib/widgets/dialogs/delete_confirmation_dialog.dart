import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final String itemName;
  final String itemType;
  final Future<void> Function()? onDelete;

  const DeleteConfirmationDialog({
    super.key,
    required this.itemName,
    required this.itemType,
    this.onDelete,
  });

  @override
  State<DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    // If no callback provided, just return true (old behavior)
    if (widget.onDelete == null) {
      Navigator.of(context).pop(true);
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the delete API
      await widget.onDelete!();

      // Close dialog on success
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Show error in dialog
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Delete ${widget.itemType}?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),

            // Message
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: '"${widget.itemName}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const TextSpan(text: '?\n\nThis action cannot be undone.'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null) const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? const Color(0xFFE5E7EB).withValues(alpha: 0.5)
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isLoading
                                ? const Color(0xFF6B7280).withValues(alpha: 0.5)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Delete button
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _handleDelete,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? AppColors.error.withValues(alpha: 0.7)
                            : AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show delete confirmation dialog
Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required String itemName,
  required String itemType,
  Future<void> Function()? onDelete,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => DeleteConfirmationDialog(
      itemName: itemName,
      itemType: itemType,
      onDelete: onDelete,
    ),
  );
  return result ?? false;
}
