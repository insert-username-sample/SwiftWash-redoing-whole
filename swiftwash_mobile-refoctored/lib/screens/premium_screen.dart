import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../upi_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  SubscriptionModel? _currentSubscription;
  bool _isLoading = true;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    setState(() => _isLoading = true);
    try {
      final subscription = await SubscriptionService().getCurrentSubscription();
      setState(() {
        _currentSubscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading subscription: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('SwiftWash Premium'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_currentSubscription?.isActive ?? false) ...[
                    _buildCurrentSubscription(),
                    const SizedBox(height: 24),
                  ],
                  _buildPlans(),
                  const SizedBox(height: 24),
                  _buildFeatures(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF04D6F7), Color(0xFF48FF4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.yellow, size: 32),
              const SizedBox(width: 12),
              Text(
                'SwiftWash Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock exclusive benefits and elevate your laundry experience',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscription() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Current Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentSubscription!.planName,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Active until ${_formatDate(_currentSubscription!.endDate)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (_currentSubscription!.daysRemaining <= 30) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                '${_currentSubscription!.daysRemaining} days remaining',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessingPayment ? null : () => _showRenewDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF04D6F7),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Renew Early',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Membership Plans',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        _buildMembershipCard(
          'Premium',
          '₹1,299/month',
          'Unlimited normal laundry orders free for a month',
          'Get unlimited access to all standard laundry services',
          true,
        ),
        const SizedBox(height: 16),
        _buildMembershipCard(
          'Swift Premium',
          '₹1,799/month',
          'Unlimited swift orders free for a month',
          'Get unlimited access to express swift laundry services',
          false,
        ),
      ],
    );
  }

  Widget _buildMembershipCard(String title, String price, String tagline, String description, bool isPopular) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular ? Border.all(color: Color(0xFF04D6F7), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Most Popular',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF04D6F7),
                      ),
                    ),
                    Text(
                      'per month',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('✓ Unlimited orders with free delivery'),
              _buildBulletPoint('✓ Priority customer support'),
              _buildBulletPoint('✓ Express laundry processing'),
              _buildBulletPoint('✓ Exclusive member discounts'),
              _buildBulletPoint('✓ Flexible scheduling options'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF04D6F7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Premium?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            'Priority Service',
            'Skip the queue and get your laundry done faster',
          ),
          _buildFeatureItem(
            'Express Delivery',
            'Same-day pickup and delivery options',
          ),
          _buildFeatureItem(
            '24/7 Support',
            'Round-the-clock customer assistance',
          ),
          _buildFeatureItem(
            'Exclusive Discounts',
            'Up to 25% off on all services',
          ),
          _buildFeatureItem(
            'Real-time Tracking',
            'Advanced GPS tracking for your orders',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star, color: Color(0xFF48FF4F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeToPlan(SubscriptionPlan plan) async {
    setState(() => _isProcessingPayment = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Initialize UPI service
      final upiService = UPIService(context);

      // Process UPI payment
      final paymentSuccess = await upiService.initiatePayment(
        amount: plan.price,
        orderId: 'premium_${DateTime.now().millisecondsSinceEpoch}',
        customerName: user.displayName ?? 'Premium User',
        customerPhone: user.phoneNumber,
        customerEmail: user.email,
      );

      if (paymentSuccess) {
        final paymentId = 'premium_${DateTime.now().millisecondsSinceEpoch}';

        // Create subscription
        final subscription = await SubscriptionService().createSubscription(
          plan: plan,
          paymentId: paymentId,
        );

        if (subscription != null) {
          setState(() {
            _currentSubscription = subscription;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully subscribed to ${plan.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to create subscription');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was cancelled or failed.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Subscription error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _showRenewDialog() {
    final plans = SubscriptionPlan.plans;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renew Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a plan to renew your subscription:'),
            const SizedBox(height: 16),
            ...plans.map((plan) => ListTile(
              title: Text(plan.name),
              subtitle: Text('₹${plan.price.toInt()} for ${plan.durationDays} days'),
              onTap: () {
                Navigator.of(context).pop();
                _renewSubscription(plan);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your premium subscription? '
          'You will lose access to premium features at the end of your current billing period.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelSubscription();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  Future<void> _renewSubscription(SubscriptionPlan plan) async {
    if (_currentSubscription == null) return;

    setState(() => _isProcessingPayment = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Initialize UPI service
      final upiService = UPIService(context);

      // Process UPI payment
      final paymentSuccess = await upiService.initiatePayment(
        amount: plan.price,
        orderId: 'renewal_${DateTime.now().millisecondsSinceEpoch}',
        customerName: user.displayName ?? 'Premium User',
        customerPhone: user.phoneNumber,
        customerEmail: user.email,
      );

      if (paymentSuccess) {
        final paymentId = 'renewal_${DateTime.now().millisecondsSinceEpoch}';

        // Renew subscription
        final updatedSubscription = await SubscriptionService().renewSubscription(
          subscriptionId: _currentSubscription!.id,
          plan: plan,
          paymentId: paymentId,
        );

        if (updatedSubscription != null) {
          setState(() {
            _currentSubscription = updatedSubscription;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully renewed ${plan.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to renew subscription');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was cancelled or failed.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Renewal error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Renewal failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _cancelSubscription() async {
    if (_currentSubscription == null) return;

    try {
      final success = await SubscriptionService().cancelSubscription(_currentSubscription!.id);

      if (success) {
        setState(() {
          _currentSubscription = _currentSubscription!.copyWith(status: 'cancelled');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled successfully. You will retain premium access until the end of your billing period.'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        throw Exception('Failed to cancel subscription');
      }
    } catch (e) {
      print('Cancel error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel subscription: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
