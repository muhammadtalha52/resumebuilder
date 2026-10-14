import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/backend_plan_model.dart';
import '../../models/purchase_product_model.dart';
import '../../models/student_plan_model.dart';
import '../../providers/iap_provider.dart';
import '../../providers/stripe_subscription_provider.dart';
import '../../providers/usage_provider.dart';
import '../../widgets/plans/active_subscription_card.dart';
import '../../widgets/plans/student_plan_card.dart';
import '../../widgets/plans/subscription_dialogs.dart';
import '../../widgets/plans/subscription_plan_card.dart';
import '../../widgets/plans/subscription_rules_widget.dart';

class StudentPlansScreen extends ConsumerStatefulWidget {
  const StudentPlansScreen({super.key});

  @override
  ConsumerState<StudentPlansScreen> createState() => _StudentPlansScreenState();
}

class _StudentPlansScreenState extends ConsumerState<StudentPlansScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  final PageController _iapPageController =
      PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  int _currentIapPage = 0;
  int _selectedTab = 0; // 0 = Subscriptions (Stripe), 1 = One-Time Packs

  // Documented fallback plans for Student (role 2)
  static const List<BackendPlanModel> _fallbackStudentPlans = [
    BackendPlanModel(
      id: 21,
      name: 'Cram Session',
      price: '3.99',
      billingInterval: 'week',
      quizCount: 12,
      documentUploadCount: 25,
      trialDays: 0,
      isSubscription: true,
    ),
    BackendPlanModel(
      id: 22,
      name: 'Basic Student',
      price: '5.00',
      billingInterval: 'month',
      quizCount: 10,
      documentUploadCount: 20,
      trialDays: 0,
      isSubscription: true,
    ),
    BackendPlanModel(
      id: 23,
      name: 'Mid Student',
      price: '10.00',
      billingInterval: 'month',
      quizCount: 25,
      documentUploadCount: 50,
      trialDays: 0,
      isSubscription: true,
    ),
    BackendPlanModel(
      id: 24,
      name: 'Nerd Out',
      price: '15.00',
      billingInterval: 'month',
      quizCount: 50,
      documentUploadCount: 100,
      trialDays: 0,
      isSubscription: true,
      isRecommended: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load Stripe subscription plans for Student (role 2)
      ref.read(stripeSubscriptionProvider.notifier).loadData(role: 2);
      // Load legacy IAP mapping
      ref.read(iapProvider.notifier).loadPlansMapping();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _iapPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final pendingSessionId =
          ref.read(stripeSubscriptionProvider).pendingSessionId;
      if (pendingSessionId != null && pendingSessionId.isNotEmpty) {
        ref
            .read(stripeSubscriptionProvider.notifier)
            .verifySession(pendingSessionId);
      } else {
        ref.read(stripeSubscriptionProvider.notifier).refreshSubscription();
      }
      ref.read(usageProvider.notifier).fetchUsageAllocation();
    }
  }

  Future<void> _onStripePlanSelected(
    BackendPlanModel plan,
    StripeSubscriptionNotifier notifier,
  ) async {
    final stripeState = ref.read(stripeSubscriptionProvider);
    final currentSub = stripeState.subscription;

    if (currentSub != null && currentSub.isActiveOrTrial) {
      if (currentSub.plan.id == plan.id) {
        return;
      }
      final confirmed = await SubscriptionDialogs.showPlanChangeDialog(
        context: context,
        targetPlan: plan,
        currentSubscription: currentSub,
      );

      if (confirmed == true && mounted) {
        await notifier.updateSubscriptionPlan(context, plan);
        ref.read(usageProvider.notifier).fetchUsageAllocation();
      }
    } else {
      await notifier.startCheckout(context, plan);
      ref.read(usageProvider.notifier).fetchUsageAllocation();
    }
  }

  Future<void> _onIapPlanSelected(BackendPlanModel plan) async {
    final iapState = ref.read(iapProvider);
    if (!iapState.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              iapState.error ?? 'In-app purchases are not available',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    String productId = plan.productId ?? '';
    if (productId.isEmpty) {
      final name = plan.name.toLowerCase();
      if (name.contains('cram')) {
        productId = PurchaseProducts.cramSessionProductId;
      } else if (name.contains('basic')) {
        productId = PurchaseProducts.basicStudentProductId;
      } else if (name.contains('mid')) {
        productId = PurchaseProducts.midStudentProductId;
      } else if (name.contains('nerd')) {
        productId = PurchaseProducts.nerdOutProductId;
      } else {
        productId = PurchaseProducts.studentBasicProductId;
      }
    }

    print('[StudentPlansScreen] Initiating Store IAP purchase for product: $productId');
    await ref.read(iapProvider.notifier).purchaseProduct(productId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StripeSubscriptionState>(stripeSubscriptionProvider,
        (previous, next) {
      if (next.successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(stripeSubscriptionProvider.notifier).clearSuccessMessage();
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

    ref.listen<IAPState>(iapProvider, (previous, next) {
      if (next.successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(iapProvider.notifier).clearSuccessMessage();
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
                        const SizedBox(height: 12),
                        _buildTypeTabs(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Active Subscription Banner if user has one
                  if (_selectedTab == 0 &&
                      stripeState.hasActiveSubscription)
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
                      height: 520,
                      child: _selectedTab == 0
                          ? _buildStripePlansCarousel(stripeState)
                          : _buildIapPlansCarousel(iapState, stripeState),
                    ),
                  ),

                  // Page Indicator and Rules
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildPageIndicator(stripeState),
                        const SizedBox(height: 12),
                        if (_selectedTab == 0)
                          const SubscriptionRulesWidget(isStudent: true),
                        const SizedBox(height: AppSizes.paddingL),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay during checkout verification (after returning from browser sheet)
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
                        'Verifying your student subscription...',
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

  Widget _buildTypeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
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
                onTap: () {
                  setState(() {
                    _selectedTab = 0;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Subscriptions (Stripe)',
                    style: TextStyle(
                      color: _selectedTab == 0
                          ? AppColors.primary
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = 1;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == 1
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'One-Time Packs',
                    style: TextStyle(
                      color: _selectedTab == 1
                          ? AppColors.primary
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  Widget _buildStripePlansCarousel(StripeSubscriptionState state) {
    final plans =
        state.plans.isNotEmpty ? state.plans : _fallbackStudentPlans;
    final notifier = ref.read(stripeSubscriptionProvider.notifier);

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isPlanCheckingOut = state.checkingOutPlanId == plan.id;
        return SubscriptionPlanCard(
          plan: plan,
          currentSubscription: state.subscription,
          onSelect: () => _onStripePlanSelected(plan, notifier),
          isLoading: isPlanCheckingOut || state.isUpdating,
        );
      },
    );
  }

  Widget _buildIapPlansCarousel(
      IAPState iapState, StripeSubscriptionState stripeState) {
    final plans =
        stripeState.plans.isNotEmpty ? stripeState.plans : _fallbackStudentPlans;

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
          onSelect: () => _onIapPlanSelected(plan),
          isLoading:
              iapState.isLoadingPlansMapping || iapState.isPurchasing,
        );
      },
    );
  }

  Widget _buildHeaderWithTitleAndClose(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            height: 210,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Image.asset(
                  'assets/icons/fox-mascot.png',
                  height: 125,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL,
              ),
              child: Text(
                'Student Learning Plans',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.primary),
                onPressed: () => context.pop(),
              ),
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
        'Supercharge your academic study sessions and quizzes with AI assistance',
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
        : _fallbackStudentPlans.length;
    final activeIndex = _selectedTab == 0 ? _currentPage : _currentIapPage;

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
