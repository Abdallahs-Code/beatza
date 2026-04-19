import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../widgets/PaymentCheckoutSheet.dart';
import 'premium_subscription.dart';

class PromoSubscriptionScreen extends StatefulWidget {
  const PromoSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<PromoSubscriptionScreen> createState() => _PromoSubscriptionScreenState();
}

class _PromoSubscriptionScreenState extends State<PromoSubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);

    try {
      final apiPlans = await PaymentService.getPlans();
      final proMonthlyApi = apiPlans['pro_monthly'];
      final plan = {
        'id': 'pro_monthly',
        'name': 'Artist Pro',
        'amount': proMonthlyApi != null ? proMonthlyApi['amount'].toString() : '164.99',
        'priceId': proMonthlyApi != null ? proMonthlyApi['priceId'] : null,
      };

      setState(() => _isLoading = false);

      if (plan['priceId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan ID missing. Please check API.')),
        );
        return;
      }
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PaymentCheckoutSheet(plan: plan),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: SizedBox(
                            width: 280,
                            height: constraints.maxHeight * 0.38,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 240,
                                    height: constraints.maxHeight * 0.35,
                                    color: const Color(0xFFF6A039),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
                                    width: 240,
                                    height: constraints.maxHeight * 0.35,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.stars, color: Color(0xFFFF3D00), size: 14),
                                  SizedBox(width: 4),
                                  Text('ARTIST PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('FOR ARTISTS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Unlock artist tools\n& unlimited\nuploads.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 16),

                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, height: 1.5),
                            children: [
                              TextSpan(text: ' 164.99/month. Cancel anytime.\n', style: TextStyle(color: Colors.white70)),
                              TextSpan(text: 'Restrictions apply.', style: TextStyle(color: Color(0xFF0A84FF))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: _isLoading ? null : _handleContinue,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
                              );
                            },
                            child: const Text('See all plans', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}