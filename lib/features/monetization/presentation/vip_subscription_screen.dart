import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';

class VipPlan {
  final String id;
  final String name;
  final String duration;
  final double priceUsd;
  final int priceKhr;
  final String? badge;
  final String savings;

  const VipPlan({
    required this.id,
    required this.name,
    required this.duration,
    required this.priceUsd,
    required this.priceKhr,
    this.badge,
    this.savings = '',
  });
}

const List<VipPlan> vipPlans = [
  VipPlan(
    id: 'vip_1_month',
    name: '១ ខែ (1 Month)',
    duration: '៣០ ថ្ងៃ',
    priceUsd: 1.50,
    priceKhr: 6000,
    savings: 'ស្តង់ដារ',
  ),
  VipPlan(
    id: 'vip_3_months',
    name: '៣ ខែ (3 Months)',
    duration: '៩០ ថ្ងៃ',
    priceUsd: 4.00,
    priceKhr: 16000,
    badge: 'ពេញនិយម (Popular)',
    savings: 'សន្សំ ១១%',
  ),
  VipPlan(
    id: 'vip_1_year',
    name: '១ ឆ្នាំ (1 Year)',
    duration: '៣៦៥ ថ្ងៃ',
    priceUsd: 12.00,
    priceKhr: 48000,
    badge: 'តម្លៃល្អបំផុត (Best Value)',
    savings: 'សន្សំ ៣៣%',
  ),
];

class VipSubscriptionScreen extends ConsumerStatefulWidget {
  const VipSubscriptionScreen({super.key});

  @override
  ConsumerState<VipSubscriptionScreen> createState() => _VipSubscriptionScreenState();
}

class _VipSubscriptionScreenState extends ConsumerState<VipSubscriptionScreen> {
  int _selectedPlanIndex = 1; // Default to 3 months popular

  void _openKhqrSheet(VipPlan plan) {
    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('សូមចូលគណនីជាមុនសិន ដើម្បីដំឡើងជា VIP'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final randomRef = 'KHP-${Random().nextInt(899999) + 100000}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _KhqrPaymentSheet(
        plan: plan,
        userId: user.id,
        transactionRef: randomRef,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    final isVip = profile?.isVipActive ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'VIP Membership',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Crown Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1A47), Color(0xFF1D102F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFFC89B3C), width: 2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFC89B3C),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ដំឡើងទៅកាន់ VIP Member',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isVip
                        ? 'អ្នកជាសមាជិក VIP រួចរាល់ហើយ! (សូមអរគុណសម្រាប់ការគាំទ្រ)'
                        : 'បទពិសោធន៍ស្តាប់រឿងខ្មោចគ្មានដែនកំណត់ គ្មានពាណិជ្ជកម្មរំខាន',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isVip ? const Color(0xFFC89B3C) : Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // VIP Perks List
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF160D23),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E1A47)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'អត្ថប្រយោជន៍ពិសេសរបស់ VIP:',
                    style: TextStyle(
                      color: Color(0xFFC89B3C),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 14),
                  _VipPerkRow(
                    icon: Icons.block_rounded,
                    title: 'គ្មានផ្ទាំងពាណិជ្ជកម្ម (100% Ad-Free)',
                    subtitle: 'ស្តាប់រឿងខ្មោចដោយរលូន គ្មានការរំខានផ្ទាំងផ្សាយ',
                  ),
                  SizedBox(height: 12),
                  _VipPerkRow(
                    icon: Icons.stars_rounded,
                    title: 'ស្តាប់ភាគថ្មីៗមុនគេ (Early Access)',
                    subtitle: 'ទទួលបានរឿង និងភាគថ្មីៗស្តាប់មុនគេ ១ សប្តាហ៍',
                  ),
                  SizedBox(height: 12),
                  _VipPerkRow(
                    icon: Icons.download_done_rounded,
                    title: 'ទាញយកស្តាប់ Offline គ្មានដែនកំណត់',
                    subtitle: 'រក្សាទុករឿងពេញចិត្តស្តាប់ពេលគ្មានអ៊ីនធឺណិត',
                  ),
                  SizedBox(height: 12),
                  _VipPerkRow(
                    icon: Icons.graphic_eq_rounded,
                    title: 'សំឡេងច្បាស់កម្រិតខ្ពស់ HD Audio',
                    subtitle: 'បទពិសោធន៍សំឡេង 3D និង Sound Effects ច្បាស់រណ្តំ',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plan Selector
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ជ្រើសរើសគម្រោង VIP:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vipPlans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final plan = vipPlans[index];
                final isSelected = _selectedPlanIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlanIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFC89B3C).withValues(alpha: 0.12)
                          : const Color(0xFF160D23),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFC89B3C)
                            : const Color(0xFF2E1A47),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _selectedPlanIndex,
                          activeColor: const Color(0xFFC89B3C),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPlanIndex = val);
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    plan.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (plan.badge != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC89B3C),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        plan.badge!,
                                        style: const TextStyle(
                                          color: Color(0xFF1D102F),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${plan.duration} • ${plan.savings}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${plan.priceUsd.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFC89B3C)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${plan.priceKhr} ៛',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _openKhqrSheet(vipPlans[_selectedPlanIndex]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC89B3C),
                  foregroundColor: const Color(0xFF1D102F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: const Color(0xFFC89B3C).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                label: Text(
                  'ទូទាត់ជាមួយ Bakong KHQR (\$${vipPlans[_selectedPlanIndex].priceUsd.toStringAsFixed(2)})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _VipPerkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _VipPerkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2E1A47),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFC89B3C), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KhqrPaymentSheet extends ConsumerStatefulWidget {
  final VipPlan plan;
  final String userId;
  final String transactionRef;

  const _KhqrPaymentSheet({
    required this.plan,
    required this.userId,
    required this.transactionRef,
  });

  @override
  ConsumerState<_KhqrPaymentSheet> createState() => _KhqrPaymentSheetState();
}

class _KhqrPaymentSheetState extends ConsumerState<_KhqrPaymentSheet> {
  bool _submitting = false;

  Future<void> _handleConfirmPayment() async {
    setState(() => _submitting = true);
    try {
      final supabase = ref.read(supabaseClientProvider);

      await supabase.from('payment_transactions').insert({
        'user_id': widget.userId,
        'plan_id': widget.plan.id,
        'amount_usd': widget.plan.priceUsd,
        'amount_khr': widget.plan.priceKhr,
        'payment_method': 'bakong_khqr',
        'transaction_ref': widget.transactionRef,
        'status': 'pending',
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1D102F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
              SizedBox(width: 10),
              Text('បានបញ្ជូនជោគជ័យ!', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'សំណើសុំ VIP សម្រាប់ ${widget.plan.name} ត្រូវបានកត់ត្រាចូលក្នុងប្រព័ន្ធ។',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1A47),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'លេខសម្គាល់ Ref: ${widget.transactionRef}',
                  style: const TextStyle(
                    color: Color(0xFFC89B3C),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ក្រុមការងារនឹងផ្ទៀងផ្ទាត់ និងបើកសិទ្ធិ VIP ជូនលោកអ្នកភ្លាមៗ។ អ្នកក៏អាចផ្ញើ Slip ទៅកាន់ Telegram @khmerhorror ដើម្បីបើកភ្លាមៗបានផងដែរ។',
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('យល់ព្រម', style: TextStyle(color: Color(0xFFC89B3C), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('បរាជ័យក្នុងការបញ្ជូន: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate valid Bakong KHQR String format
    final khqrData = 'https://bakong.nbc.org.kh/pay?merchant=khmer_horror_podcast&amount=${widget.plan.priceUsd}&currency=USD&ref=${widget.transactionRef}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF160D23),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bakong KHQR Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ស្កេនជាមួយ ABA, Wing, ឬ ACLEDA',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // KHQR Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Red Bakong KHQR Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE21A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'KHQR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khmer Horror Podcast',
                  style: TextStyle(
                    color: Color(0xFF1D102F),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),

                // QR Code
                SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: khqrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1D102F),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1D102F),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  '\$${widget.plan.priceUsd.toStringAsFixed(2)}  /  ${widget.plan.priceKhr} KHR',
                  style: const TextStyle(
                    color: Color(0xFFE21A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reference & Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF221437),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E1A47)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ref: ${widget.transactionRef}',
                  style: const TextStyle(
                    color: Color(0xFFC89B3C),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.transactionRef));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('បានចម្លង Ref ID!'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Text(
                    'ចម្លង (Copy)',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Confirmation Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _handleConfirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89B3C),
                foregroundColor: const Color(0xFF1D102F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Color(0xFF1D102F), strokeWidth: 2.5),
                    )
                  : const Text(
                      'ខ្ញុំបានទូទាត់រួចរាល់ (I Have Paid)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
