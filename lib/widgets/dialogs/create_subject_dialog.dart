import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/custom_button.dart';

class CreateSubjectDialog extends StatefulWidget {
  final String? initialName;
  final String? initialEmoji;
  final Future<void> Function(String name, String emoji)? onCreateFolder;

  const CreateSubjectDialog({
    super.key,
    this.initialName,
    this.initialEmoji,
    this.onCreateFolder,
  });

  @override
  State<CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateSubjectDialogState extends State<CreateSubjectDialog> {
  late TextEditingController _nameController;
  final String _defaultEmoji = '📁';
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState!.validate()) {
      // If no callback provided, just return data (for edit mode)
      if (widget.onCreateFolder == null) {
        Navigator.of(
          context,
        ).pop({'name': _nameController.text.trim(), 'emoji': _defaultEmoji});
        return;
      }

      // Show loading state
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Call the API
        await widget.onCreateFolder!(
          _nameController.text.trim(),
          _defaultEmoji,
        );

        // Close dialog on success
        if (mounted) {
          Navigator.of(
            context,
          ).pop({'name': _nameController.text.trim(), 'emoji': _defaultEmoji});
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.initialName != null
                    ? 'Rename Subject'
                    : 'Create New Subject',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),

              // Subject Name Field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Mathematics',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderFocused,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject name';
                  }
                  if (value.trim().length < 2) {
                    return 'Subject name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
                          : () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? const Color(0xFFE5E7EB).withOpacity(0.5)
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
                                  ? const Color(0xFF6B7280).withOpacity(0.5)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Create button
                  Expanded(
                    child: CustomButton(
                      text: widget.initialName != null ? 'Save' : 'Create',
                      height: 48,
                      isLoading: _isLoading,
                      useGradient: false,
                      onPressed: _handleCreate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show create subject dialog
Future<Map<String, String>?> showCreateSubjectDialog({
  required BuildContext context,
  String? initialName,
  String? initialEmoji,
  Future<void> Function(String name, String emoji)? onCreateFolder,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CreateSubjectDialog(
      initialName: initialName,
      initialEmoji: initialEmoji,
      onCreateFolder: onCreateFolder,
    ),
  );
}
