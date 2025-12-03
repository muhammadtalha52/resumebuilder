import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/invite_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';

class InviteFriendsScreen extends ConsumerStatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  ConsumerState<InviteFriendsScreen> createState() =>
      _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends ConsumerState<InviteFriendsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inviteProvider.notifier).fetchInvites();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    await ref.read(inviteProvider.notifier).sendInvite(email);

    final inviteState = ref.read(inviteProvider);

    if (mounted) {
      if (inviteState.error != null) {
        showErrorSnackBar(context: context, message: inviteState.error!);
      } else {
        showSuccessSnackBar(
          context: context,
          message: 'Invitation sent to $email',
        );
        _emailController.clear();

        // Check if a reward was granted
        if (inviteState.reward != null) {
          _showRewardDialog();
        }
      }
    }
  }

  void _showRewardDialog() {
    final authState = ref.read(authProvider);
    final isStudent = authState.user?.role == 2;
    final rewardMessage = isStudent
        ? 'You\'ve unlocked a FREE study session! Keep learning and growing with SkillResy.'
        : 'You\'ve unlocked a FREE resume! Create your next professional resume on us.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
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
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Congratulations!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                rewardMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: GestureDetector(
                  onTap: () {
                    ref.read(inviteProvider.notifier).clearReward();
                    Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      context.pushReplacement('/usage');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Awesome!',
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(inviteProvider);
    final authState = ref.watch(authProvider);
    final isStudent = authState.user?.role == 2;

    // Check if user still needs to invite friends for reward
    final invitesSent = inviteState.sentEmails.length;
    final invitesRemaining = 3 - invitesSent;
    final showRewardText = invitesRemaining > 0;
    final rewardType = isStudent ? 'study session' : 'resume';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: 'Invite Friends',
        onBackPressed: () => context.pop(),
        showFoxIcon: true,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.only(top: 15, bottom: 15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card with Fox
                        Container(
                          padding: const EdgeInsets.all(15),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/icons/fox-for-success.png',
                                height: 100,
                                width: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.card_giftcard,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Invite Friends',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                showRewardText
                                    ? invitesSent == 0
                                          ? 'Invite 3 friends and get a FREE $rewardType!'
                                          : 'Invite $invitesRemaining more ${invitesRemaining == 1 ? 'friend' : 'friends'} and get a FREE $rewardType!'
                                    : 'Help friends and family succeed - invite them today!',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Email Input Section
                        const Text(
                          'Enter Friend\'s Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We\'ll send them an invitation to join SkillResy',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'john@gmail.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                          ),
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: 'Send Invite',
                          onPressed: inviteState.isLoading ? null : _sendInvite,
                          isLoading: inviteState.isLoading,
                          icon: Icons.send,
                        ),
                        // Sent Invites List
                        if (inviteState.sentEmails.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Sent Invites',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...inviteState.sentEmails.map((email) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const Text(
                                          'Invitation sent',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
