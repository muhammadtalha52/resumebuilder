import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/backend_plan_model.dart';
import '../../models/purchase_product_model.dart';
import '../../providers/iap_provider.dart';
import '../../providers/stripe_subscription_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/onboarding_funnel_service.dart';
import '../../widgets/plans/subscription_plan_card.dart';

/// High-converting, non-intrusive Paywall Modal.
///
/// Features:
/// - Styled exactly like the Plans Screen with AppColors.primaryGradientVertical
/// - Translucent Type Tabs (Subscriptions vs Store IAP on Android)
/// - Horizontal PageView Carousel using SubscriptionPlanCard
/// - Animated Page Indicator Dots showing count and active plan
/// - Native Apple StoreKit IAP on iOS / Stripe & Play IAP on Android
/// - Non-blocking dismissal ("✕" and "Not now") with 72-hour cooldown
class PaywallModal extends ConsumerStatefulWidget {
  final bool isStudent;
  final String triggerReason; // 'post_tour', 'no_plan', 'credits_exhausted'

  const PaywallModal({
    super.key,
    this.isStudent = false,
    this.triggerReason = 'no_plan',
  });

  /// Displays the modal dialog as a non-blocking modal sheet
  static Future<void> show(
    BuildContext context, {
    bool isStudent = false,
    String triggerReason = 'no_plan',
  }) {
    // Mark as shown in current session
    OnboardingFunnelService.instance.markPaywallShownInSession();

    // Fire paywall_shown analytics
    AnalyticsService.logPaywallShown(trigger: triggerReason);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => PaywallModal(
        isStudent: isStudent,
        triggerReason: triggerReason,
      ),
    );
  }

  @override
  ConsumerState<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends ConsumerState<PaywallModal> {
  late PageController _pageController;
  int _currentPage = 2; // Default to popular plan (index 2)
  int _selectedTab = Platform.isIOS ? 1 : 0; // On iOS force Store IAP, on Android allow both
  bool _isProcessing = false;

  // Fallback plans for Candidate (Job Seeker) - strictly aligned with StoreKit consumable products
  static const List<BackendPlanModel> _candidatePlans = [
    BackendPlanModel(
      id: 11,
      name: 'Weekend Warrior',
      productId: PurchaseProducts.weekendWarriorProductId,
      price: '10.99',
      billingInterval: null,
      resumeCount: 3,
      interviewCount: 3,
      askScoutCount: 10,
      trialDays: 0,
      isSubscription: false,
    ),
    BackendPlanModel(
      id: 12,
      name: 'Just Scouting',
      productId: PurchaseProducts.justScoutingProductId,
      price: '14.99',
      billingInterval: null,
      resumeCount: 5,
      interviewCount: 3,
      askScoutCount: 20,
      trialDays: 0,
      isSubscription: false,
    ),
    BackendPlanModel(
      id: 13,
      name: 'Serious Seeker',
      productId: PurchaseProducts.seriousSeekerProductId,
      price: '24.99',
      billingInterval: null,
      resumeCount: 12,
      interviewCount: 8,
      askScoutCount: 45,
      trialDays: 0,
      isSubscription: false,
      isRecommended: true,
    ),
    BackendPlanModel(
      id: 14,
      name: 'Job Hunter',
      productId: PurchaseProducts.jobHunterProductId,
      price: '49.99',
      billingInterval: null,
      resumeCount: 25,
      interviewCount: 15,
      askScoutCount: 100,
      trialDays: 0,
      isSubscription: false,
    ),
  ];

  // Fallback plans for Student - strictly aligned with StoreKit consumable products
  static const List<BackendPlanModel> _studentPlans = [
    BackendPlanModel(
      id: 21,
      name: 'Cram Session',
      productId: PurchaseProducts.cramSessionProductId,
      price: '3.99',
      billingInterval: null,
      quizCount: 12,
      documentUploadCount: 25,
      trialDays: 0,
      isSubscription: false,
    ),
    BackendPlanModel(
      id: 22,
      name: 'Basic Student',
      productId: PurchaseProducts.basicStudentProductId,
      price: '5.00',
      billingInterval: null,
      quizCount: 10,
      documentUploadCount: 20,
      trialDays: 0,
      isSubscription: false,
    ),
    BackendPlanModel(
      id: 23,
      name: 'Mid Student',
      productId: PurchaseProducts.midStudentProductId,
      price: '10.00',
      billingInterval: null,
      quizCount: 25,
      documentUploadCount: 50,
      trialDays: 0,
      isSubscription: false,
    ),
    BackendPlanModel(
      id: 24,
      name: 'Nerd Out',
      productId: PurchaseProducts.nerdOutProductId,
      price: '15.00',
      billingInterval: null,
      quizCount: 50,
      documentUploadCount: 100,
      trialDays: 0,
      isSubscription: false,
      isRecommended: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = 2;
    _pageController = PageController(viewportFraction: 0.88, initialPage: 2);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = widget.isStudent ? 2 : 1;
      ref.read(stripeSubscriptionProvider.notifier).loadData(role: role);
      ref.read(iapProvider.notifier).reloadProducts();
      ref.read(iapProvider.notifier).loadPlansMapping();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _dismiss(String reason) {
    OnboardingFunnelService.instance.recordPaywallDismissal();
    AnalyticsService.logPaywallDismissed(reason: reason);
    Navigator.of(context).pop();
  }

  Future<void> _handlePlanSelected(BackendPlanModel plan) async {
    AnalyticsService.logTrialStartClicked(
      planId: plan.id,
      planName: plan.name,
      price: plan.price,
    );

    setState(() => _isProcessing = true);

    try {
      if (Platform.isIOS || _selectedTab == 1) {
        // Native In-App Purchase (StoreKit on iOS / Google Play on Android)
        await _purchaseStoreKitOrPlayIAP(plan);
      } else {
        // Android: Stripe Checkout (Card with 3-Day Free Trial)
        final notifier = ref.read(stripeSubscriptionProvider.notifier);
        await notifier.startCheckout(context, plan);
      }
    } catch (e) {
      debugPrint('[PaywallModal] Purchase error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _purchaseStoreKitOrPlayIAP(BackendPlanModel plan) async {
    final iapState = ref.read(iapProvider);
    if (!iapState.isInitialized) {
      await ref.read(iapProvider.notifier).reloadProducts();
    }

    String productId = plan.productId ?? '';
    if (productId.isEmpty) {
      final name = plan.name.toLowerCase();
      if (widget.isStudent) {
        if (name.contains('cram')) {
          productId = PurchaseProducts.cramSessionProductId;
        } else if (name.contains('mid')) {
          productId = PurchaseProducts.midStudentProductId;
        } else if (name.contains('nerd')) {
          productId = PurchaseProducts.nerdOutProductId;
        } else {
          productId = PurchaseProducts.basicStudentProductId;
        }
      } else {
        if (name.contains('weekend')) {
          productId = PurchaseProducts.weekendWarriorProductId;
        } else if (name.contains('scouting') || name.contains('just')) {
          productId = PurchaseProducts.justScoutingProductId;
        } else if (name.contains('serious') || name.contains('seeker')) {
          productId = PurchaseProducts.seriousSeekerProductId;
        } else if (name.contains('hunter') || name.contains('job')) {
          productId = PurchaseProducts.jobHunterProductId;
        } else {
          productId = PurchaseProducts.weekendWarriorProductId;
        }
      }
    }

    debugPrint('[PaywallModal] Initiating Store IAP purchase for product: $productId');
    await ref.read(iapProvider.notifier).purchaseProduct(productId);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for purchase completions to trigger thank-you screen
    ref.listen<StripeSubscriptionState>(stripeSubscriptionProvider, (prev, next) {
      if (next.successMessage != null && mounted) {
        ref.read(stripeSubscriptionProvider.notifier).clearSuccessMessage();
        Navigator.of(context).pop();
        context.go('/thank-you', extra: {'isTrial': !widget.isStudent});
      } else if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(stripeSubscriptionProvider.notifier).clearError();
      }
    });

    ref.listen<IAPState>(iapProvider, (prev, next) {
      if (next.successMessage != null && mounted) {
        ref.read(iapProvider.notifier).clearSuccessMessage();
        Navigator.of(context).pop();
        context.go('/thank-you', extra: {'isTrial': false});
      } else if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(iapProvider.notifier).clearError();
      }
    });

    final stripeState = ref.watch(stripeSubscriptionProvider);
    final iapState = ref.watch(iapProvider);
    final stripePlans = stripeState.plans;
    final fallbackList = widget.isStudent ? _studentPlans : _candidatePlans;
    final activePlans = stripePlans.isNotEmpty ? stripePlans : fallbackList;

    if (_currentPage >= activePlans.length) {
      _currentPage = 0;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final modalHeight = (screenHeight * 0.92).clamp(660.0, 820.0);
    final carouselHeight = (screenHeight * 0.52).clamp(415.0, 445.0);

    final bool isOneTime = Platform.isIOS || _selectedTab == 1;
    final trialPlan = activePlans.cast<BackendPlanModel?>().firstWhere(
      (p) => p != null && p.hasTrial,
      orElse: () => null,
    );
    final trialDaysCount = trialPlan?.trialDays ?? 7;

    return Container(
      height: modalHeight,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradientVertical,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Top Badge Pill (Apple StoreKit compliant)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        Platform.isIOS
                            ? (widget.isStudent
                                ? 'Student Learning Packs • Instant Activation'
                                : 'One-Time Packs • Instant Activation')
                            : (_selectedTab == 1
                                ? 'Google Play Billing • Instant Activation'
                                : (widget.isStudent
                                    ? 'Student Special Access'
                                    : '$trialDaysCount-Day Free Trial Included')),
                        style: TextStyle(
                          color: (!Platform.isIOS && _selectedTab == 1)
                              ? const Color(0xFF01875F)
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Main Heading (Plans Screen style)
                Text(
                  widget.isStudent
                      ? 'Ace Your Studies With AI'
                      : 'Choose Your Plan',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle (Plans Screen style)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: Text(
                    widget.isStudent
                        ? 'Summarize lectures, practice unlimited AI quizzes, and excel in every course.'
                        : 'Tap into AI tools that fine-tune your resume and interview skills for your dream job',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                ),

                // Type Tabs (Only on Android, exactly matching CandidatePlansScreen)
                if (!Platform.isIOS) ...[
                  const SizedBox(height: 14),
                  _buildTypeTabs(screenWidth),
                ],
                const SizedBox(height: 12),

                // Horizontal Plans Carousel
                if (stripeState.isLoading && stripePlans.isEmpty)
                  Container(
                    height: 460,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Loading plans...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    height: carouselHeight,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: activePlans.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final rawPlan = activePlans[index];
                        final isPlanCheckingOut =
                            stripeState.checkingOutPlanId == rawPlan.id;

                        // On iOS or Store IAP, enforce one-time consumable presentation
                        final plan = isOneTime
                            ? rawPlan.copyWith(
                                isSubscription: false,
                                trialDays: 0,
                                billingInterval: null,
                              )
                            : rawPlan;

                        return Align(
                          alignment: Alignment.topCenter,
                          child: SubscriptionPlanCard(
                            plan: plan,
                            currentSubscription: stripeState.subscription,
                            isOneTime: isOneTime,
                            customButtonText: isOneTime ? 'Get Plan' : null,
                            onSelect: () => _handlePlanSelected(plan),
                            isLoading: _isProcessing ||
                                isPlanCheckingOut ||
                                stripeState.isUpdating ||
                                iapState.isPurchasing,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Page Indicator Dots (Dots showing count and active plan)
                  _buildPageIndicator(activePlans.length, _currentPage),
                ],

                const SizedBox(height: 16),

                // Credits Renewal Notice
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: Text(
                    isOneTime
                        ? 'One-time purchase. Credits are added instantly to your account.'
                        : 'Credits renew each period. Unused credits expire. Cancel anytime before trial ends with zero charge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // "Not now" button
                GestureDetector(
                  onTap: () => _dismiss('not_now'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Not now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dismiss ✕ Button (Top-Right Glassmorphism)
          Positioned(
            top: 14,
            right: 16,
            child: GestureDetector(
              onTap: () => _dismiss('close_button'),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Translucent Type Tabs matching CandidatePlansScreen
  Widget _buildTypeTabs(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Subscriptions (Stripe)',
                    style: TextStyle(
                      color: _selectedTab == 0 ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Google Play Store',
                    style: TextStyle(
                      color: _selectedTab == 1 ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Page Indicator Dots matching Plans Screen design
  Widget _buildPageIndicator(int count, int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: activeIndex == index ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: activeIndex == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
