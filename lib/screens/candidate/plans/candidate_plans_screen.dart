import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../main.dart';
import '../../../services/analytics_service.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../models/backend_plan_model.dart';

import '../../../models/purchase_product_model.dart';
import '../../../providers/iap_provider.dart';
import '../../../providers/stripe_subscription_provider.dart';
import '../../../providers/usage_provider.dart';
import '../../../widgets/plans/active_subscription_card.dart';

import '../../../widgets/plans/subscription_dialogs.dart';
import '../../../widgets/plans/subscription_plan_card.dart';
import '../../../widgets/plans/subscription_legal_footer.dart';
import '../../../widgets/plans/trial_hero_banner.dart';

class CandidatePlansScreen extends ConsumerStatefulWidget {
  const CandidatePlansScreen({super.key});

  @override
  ConsumerState<CandidatePlansScreen> createState() =>
      _CandidatePlansScreenState();
}

class _CandidatePlansScreenState extends ConsumerState<CandidatePlansScreen>
    with WidgetsBindingObserver {
  final PageController _iapPageController =
      PageController(viewportFraction: 0.92);
  int _currentIapPage = 0;
  String? _lastSelectedPlanId;

  // Documented fallback plans for candidate (role 1) if offline/syncing
  static const List<BackendPlanModel> _fallbackCandidatePlans = [
    BackendPlanModel(
      id: 11,
      name: 'Weekend Warrior',
      productId: PurchaseProducts.weekendWarriorProductId,
      price: '10.99',
      billingInterval: 'week',
      resumeCount: 3,
      interviewCount: 3,
      askScoutCount: 10,
      trialDays: 7,
      trialResumeCount: 3,
      trialInterviewCount: 2,
      isSubscription: true,
    ),
    BackendPlanModel(
      id: 12,
      name: 'Just Scouting',
      productId: PurchaseProducts.justScoutingProductId,
      price: '14.99',
      billingInterval: 'month',
      resumeCount: 5,
      interviewCount: 3,
      askScoutCount: 20,
      trialDays: 7,
      trialResumeCount: 3,
      trialInterviewCount: 2,
      isSubscription: true,
    ),
    BackendPlanModel(
      id: 13,
      name: 'Serious Seeker',
      productId: PurchaseProducts.seriousSeekerProductId,
      price: '24.99',
      billingInterval: 'month',
      resumeCount: 12,
      interviewCount: 8,
      askScoutCount: 45,
      trialDays: 7,
      trialResumeCount: 3,
      trialInterviewCount: 2,
      isSubscription: true,
      isRecommended: true,
    ),
    BackendPlanModel(
      id: 14,
      name: 'Job Hunter',
      productId: PurchaseProducts.jobHunterProductId,
      price: '49.99',
      billingInterval: 'month',
      resumeCount: 25,
      interviewCount: 15,
      askScoutCount: 100,
      trialDays: 7,
      trialResumeCount: 3,
      trialInterviewCount: 2,
      isSubscription: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.logPaywallShown(trigger: 'candidate_plans_screen');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appLogic.accessToken.isNotEmpty) {
        // Load Stripe subscription plans only on Android
        if (!Platform.isIOS) {
          ref.read(stripeSubscriptionProvider.notifier).loadData(role: 1);
        }
        // Always load store IAP mapping
        ref.read(iapProvider.notifier).reloadProducts();
        ref.read(iapProvider.notifier).loadPlansMapping();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _iapPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (appLogic.accessToken.isEmpty) return;
      if (!Platform.isAndroid) {
        // Re-check pending checkout or refresh subscription status upon returning
        final pendingSessionId =
            ref.read(stripeSubscriptionProvider).pendingSessionId;
        if (pendingSessionId != null && pendingSessionId.isNotEmpty) {
          ref
              .read(stripeSubscriptionProvider.notifier)
              .verifySession(pendingSessionId);
        } else {
          ref.read(stripeSubscriptionProvider.notifier).refreshSubscription();
        }
      } else {
        ref.read(stripeSubscriptionProvider.notifier).refreshSubscription();
      }
      ref.read(usageProvider.notifier).fetchUsageAllocation();
    }
  }

  Future<bool> _ensureAuthenticated() async {
    if (appLogic.accessToken.isNotEmpty) return true;
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Account Required', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Please log in or create an account to subscribe to this plan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log In / Sign Up'),
          ),
        ],
      ),
    );
    if (shouldLogin == true && mounted) {
      context.push('/login');
    }
    return false;
  }

  Future<void> _onIapPlanSelected(BackendPlanModel plan) async {
    _lastSelectedPlanId = plan.id.toString();
    if (!await _ensureAuthenticated()) return;
    if (!mounted) return;
    final iapState = ref.read(iapProvider);
    if (!iapState.isInitialized) {
      await ref.read(iapProvider.notifier).reloadProducts();
    }

    String productId = plan.productId ?? '';
    if (productId.isEmpty) {
      final name = plan.name.toLowerCase();
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

    print('[PlansScreen] Initiating Store IAP purchase for product: $productId');
    await ref.read(iapProvider.notifier).purchaseProduct(productId);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Stripe subscription messages
    ref.listen<StripeSubscriptionState>(stripeSubscriptionProvider,
        (previous, next) {
      if (next.successMessage != null && mounted) {
        ref.read(stripeSubscriptionProvider.notifier).clearSuccessMessage();
        context.go('/thank-you', extra: {'isTrial': true});
      } else if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(stripeSubscriptionProvider.notifier).clearError();
      }
    });

    // Listen to legacy IAP state
    ref.listen<IAPState>(iapProvider, (previous, next) {
      if (next.successMessage != null && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ref.read(iapProvider.notifier).clearSuccessMessage();
        AnalyticsService.logTrialStartedFromPaywall(
          userType: 'candidate',
          planId: _lastSelectedPlanId ?? 'unknown',
        );
        ref.read(usageProvider.notifier).fetchUsageAllocation();
        ref.read(stripeSubscriptionProvider.notifier).refreshSubscription();
        context.go('/thank-you', extra: {'isTrial': true});
      } else if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(iapProvider.notifier).clearError();
      }
    });

    final stripeState = ref.watch(stripeSubscriptionProvider);
    final iapState = ref.watch(iapProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradientVertical,
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildHeaderWithTitleAndClose(context),
                        _buildSubtitle(),
                        const SizedBox(height: 8),
                        TrialHeroBanner(
                          isStudent: false,
                          isLoading: iapState.isLoadingPlansMapping ||
                              iapState.isPurchasing,
                          onStartTrial: () {
                            final plans = stripeState.plans.isNotEmpty
                                ? stripeState.plans
                                : _fallbackCandidatePlans;
                            final targetIndex = _currentIapPage < plans.length
                                ? _currentIapPage
                                : 0;
                            _onIapPlanSelected(plans[targetIndex]);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Active Subscription Banner if user has one
                  if (stripeState.hasActiveSubscription)
                    SliverToBoxAdapter(
                      child: ActiveSubscriptionCard(
                        subscription: stripeState.subscription!,
                        payments: stripeState.payments,
                        isCanceling: stripeState.isCanceling,
                        onCancelOrUndo: () async {
                          final confirmed =
                              await SubscriptionDialogs.showCancelConfirmationDialog(
                            context: context,
                            subscription: stripeState.subscription!,
                          );
                          if (confirmed == true && mounted) {
                            await ref
                                .read(stripeSubscriptionProvider.notifier)
                                .cancelOrResumeSubscription(
                                  undo: stripeState
                                      .subscription!.cancelAtPeriodEnd,
                                );
                            ref
                                .read(usageProvider.notifier)
                                .fetchUsageAllocation();
                          }
                        },
                        onOpenInvoice: (url) {
                          ref
                              .read(stripeSubscriptionProvider.notifier)
                              .openInvoice(url);
                        },
                      ),
                    ),

                  // Plans Carousel
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 650,
                      child: _buildIapPlansCarousel(iapState, stripeState),
                    ),
                  ),

                  // Page Indicator
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildPageIndicator(stripeState),
                        const SizedBox(height: 12),
                        const SubscriptionLegalFooter(lightText: true),
                        const SizedBox(height: AppSizes.paddingL),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay during checkout verification (after returning from checkout sheet)
          if (stripeState.isVerifying)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 18),
                      Text(
                        'Verifying your subscription...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIapPlansCarousel(
      IAPState iapState, StripeSubscriptionState stripeState) {
    final plans =
        stripeState.plans.isNotEmpty ? stripeState.plans : _fallbackCandidatePlans;

    return PageView.builder(
      controller: _iapPageController,
      onPageChanged: (index) {
        setState(() {
          _currentIapPage = index;
        });
      },
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return SubscriptionPlanCard(
          plan: plan,
          currentSubscription: stripeState.subscription,
          isOneTime: false,
          onSelect: () => _onIapPlanSelected(plan),
          isLoading:
              iapState.isLoadingPlansMapping || iapState.isPurchasing,
          onRestorePurchases: () => ref.read(iapProvider.notifier).restorePurchases(),
        );
      },
    );
  }

  Widget _buildHeaderWithTitleAndClose(BuildContext context) {
    final stripeState = ref.watch(stripeSubscriptionProvider);
    final trialPlan = stripeState.plans.cast<BackendPlanModel?>().firstWhere(
      (p) => p != null && p.hasTrial,
      orElse: () => null,
    );
    final trialDaysCount = trialPlan?.trialDays ?? 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/icons/fox-mascot.png',
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$trialDaysCount-Day Free Trial',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(
                        appLogic.accessToken.isNotEmpty ? '/home' : '/welcome',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pricing Plans',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: 4),
      child: Text(
        'Choose the perfect plan for your career growth. All plans include our core AI features.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPageIndicator(StripeSubscriptionState state) {
    final count = state.plans.isNotEmpty
        ? state.plans.length
        : _fallbackCandidatePlans.length;
    final activeIndex = _currentIapPage;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: activeIndex == index ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: activeIndex == index
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
