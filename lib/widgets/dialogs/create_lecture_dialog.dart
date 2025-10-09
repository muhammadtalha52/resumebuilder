import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class CreateLectureDialog extends StatefulWidget {
  final String? initialName;
  final Future<void> Function(String name, String emoji)? onCreateFolder;

  const CreateLectureDialog({super.key, this.initialName, this.onCreateFolder});

  @override
  State<CreateLectureDialog> createState() => _CreateLectureDialogState();
}

class _CreateLectureDialogState extends State<CreateLectureDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
      final lectureName = _nameController.text.trim();

      if (widget.onCreateFolder != null) {
        setState(() => _isLoading = true);
        try {
          await widget.onCreateFolder!(lectureName, '');
          if (mounted) {
            Navigator.of(context).pop({'name': lectureName});
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        Navigator.of(context).pop({'name': lectureName});
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.initialName != null
                    ? 'Rename Lecture'
                    : 'Add New Lecture',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),

              // Lecture Name Field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Lecture Name',
                  hintText: 'e.g., Lecture 1, Introduction',
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
                    return 'Please enter a lecture name';
                  }
                  if (value.trim().length < 2) {
                    return 'Lecture name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Create button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _handleCreate,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.initialName != null ? 'Save' : 'Add',
                                  style: const TextStyle(
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
      ),
    );
  }
}

// Helper function to show create lecture dialog
Future<Map<String, String>?> showCreateLectureDialog({
  required BuildContext context,
  String? initialName,
  Future<void> Function(String name, String emoji)? onCreateFolder,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CreateLectureDialog(
      initialName: initialName,
      onCreateFolder: onCreateFolder,
    ),
  );
}
