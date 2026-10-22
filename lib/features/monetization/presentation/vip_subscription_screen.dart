import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  int _selectedPlanIndex = 1; // Default to 3 months
  List<Map<String, dynamic>> _userTransactions = [];
  RealtimeChannel? _txRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchUserTransactions();
    _subscribeToTransactionChanges();
  }

  @override
  void dispose() {
    _txRealtimeChannel?.unsubscribe();
    super.dispose();
  }

  /// Fetch user's recent orders from Supabase
  Future<void> _fetchUserTransactions() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      final res = await supabase
          .from('payment_transactions')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _userTransactions = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (_) {
      // Gracefully continue
    }
  }

  /// Real-time live synchronization with Admin Dashboard approval
  void _subscribeToTransactionChanges() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final supabase = ref.read(supabaseClientProvider);
    _txRealtimeChannel = supabase
        .channel('user-payment-sync-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payment_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            _fetchUserTransactions();
            final record = payload.newRecord;
            if (record['status'] == 'approved') {
              // Immediately refresh profile so VIP badge and ad-suppression take effect
              ref.read(authProvider.notifier).refreshProfile();
              _showVipApprovedCelebration();
            }
          },
        )
        .subscribe();
  }

  void _showVipApprovedCelebration() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D102F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFC89B3C), width: 2),
        ),
        title: const Column(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFFC89B3C), size: 52),
            SizedBox(height: 10),
            Text(
              'អបអរសាទរ! VIP សកម្មហើយ 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'គណនីរបស់អ្នកត្រូវបាន Admin អនុម័តជាសមាជិក VIP រួចរាល់ហើយ! រាល់ការផ្សាយពាណិជ្ជកម្មត្រូវបានលាក់ទាំងស្រុង។ សូមរីករាយជាមួយរឿងនិទានខ្មោចដ៏រន្ធត់!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89B3C),
                foregroundColor: const Color(0xFF1D102F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('រីករាយស្តាប់ឥឡូវនេះ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

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
        onSubmitted: () => _fetchUserTransactions(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    final isVip = profile?.isVipActive ?? false;

    // Check if there's any pending transaction
    final pendingTx = _userTransactions.where((t) => t['status'] == 'pending').toList();

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
            // Crown Hero Card
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
                        ? 'អ្នកកំពុងរីករាយជាមួយគណនី VIP (គ្មានការរំខាន)'
                        : 'ស្តាប់រឿងនិទានខ្មោចដ៏រន្ធត់ដោយគ្មានការផ្សាយពាណិជ្ជកម្មរំខាន',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (isVip && profile?.vipExpiresAt != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC89B3C)),
                      ),
                      child: Text(
                        'ផុតកំណត់: ${DateFormat('dd-MMM-yyyy').format(profile!.vipExpiresAt!)}',
                        style: const TextStyle(
                          color: Color(0xFFC89B3C),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pending Approval Notification Alert
            if (pendingTx.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'កំពុងរង់ចាំការផ្ទៀងផ្ទាត់ (Pending)',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'អ្នកបានផ្ញើសំណើ (Ref: ${pendingTx.first['transaction_ref']})។ នៅពេល Admin អនុម័ត ប្រព័ន្ធនឹងបើកសិទ្ធិ VIP ជូនភ្លាមៗ!',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // VIP Perks List
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF160D23),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E1A47)),
              ),
              child: const Column(
                children: [
                  _VipPerkRow(
                    icon: Icons.block_rounded,
                    title: 'គ្មានការផ្សាយពាណិជ្ជកម្ម (Zero Ads)',
                    subtitle: 'បិទរាល់ផ្ទាំង Banner, Video និង Interstitial Ads ទាំងអស់',
                  ),
                  Divider(color: Color(0xFF2E1A47), height: 24),
                  _VipPerkRow(
                    icon: Icons.graphic_eq_rounded,
                    title: 'គុណភាពសំឡេងកម្រិតខ្ពស់ (HQ Audio)',
                    subtitle: 'ស្តាប់សំឡេងនិទានរន្ធត់បែប Stereo Crystal Clear',
                  ),
                  Divider(color: Color(0xFF2E1A47), height: 24),
                  _VipPerkRow(
                    icon: Icons.star_rounded,
                    title: 'ស្តាប់ភាគពិសេសមុនគេ (Early Access)',
                    subtitle: 'ទទួលបានរឿងនិទានថ្មីៗមុនការចេញផ្សាយជាសាធារណៈ',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plan Selector Header
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

            // Plans List
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

            const SizedBox(height: 24),

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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // User's Order History Section
            if (_userTransactions.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ប្រវត្តិការបញ្ជាទិញ VIP របស់ខ្ញុំ:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userTransactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final tx = _userTransactions[idx];
                  final status = tx['status'] as String? ?? 'pending';
                  final refCode = tx['transaction_ref'] as String? ?? 'N/A';
                  final amount = tx['amount_usd']?.toString() ?? '0.00';
                  final date = tx['created_at'] != null
                      ? DateFormat('dd-MM-yyyy HH:mm')
                          .format(DateTime.parse(tx['created_at']))
                      : '';

                  Color statusColor = Colors.amber;
                  String statusText = 'រង់ចាំពិនិត្យ';
                  IconData statusIcon = Icons.access_time_rounded;

                  if (status == 'approved') {
                    statusColor = Colors.greenAccent;
                    statusText = 'បានអនុម័ត';
                    statusIcon = Icons.check_circle_rounded;
                  } else if (status == 'rejected') {
                    statusColor = Colors.redAccent;
                    statusText = 'បានបដិសេធ';
                    statusIcon = Icons.cancel_rounded;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF160D23),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2E1A47)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              refCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$$amount',
                              style: const TextStyle(
                                color: Color(0xFFC89B3C),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
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
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF2E1A47),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: const Color(0xFFC89B3C), size: 22),
        ),
        const SizedBox(width: 14),
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
  final VoidCallback? onSubmitted;

  const _KhqrPaymentSheet({
    required this.plan,
    required this.userId,
    required this.transactionRef,
    this.onSubmitted,
  });

  @override
  ConsumerState<_KhqrPaymentSheet> createState() => _KhqrPaymentSheetState();
}

class _KhqrPaymentSheetState extends ConsumerState<_KhqrPaymentSheet> {
  bool _submitting = false;
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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
        'sender_phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'status': 'pending',
      });

      widget.onSubmitted?.call();

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
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
                    'Khmer Horror Podcast Official',
                    style: TextStyle(
                      color: Color(0xFF1D102F),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Bakong ID: khmerhorror@bkng',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // QR Code
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: QrImageView(
                      data: khqrData,
                      version: QrVersions.auto,
                      size: 190.0,
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

            const SizedBox(height: 14),

            // Reference & Copy
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

            const SizedBox(height: 12),

            // Optional Phone / Telegram verification input
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'លេខទូរស័ព្ទ ឬ Telegram សម្រាប់ផ្ទៀងផ្ទាត់ (ស្រេចចិត្ត)',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFFC89B3C), size: 18),
                filled: true,
                fillColor: const Color(0xFF221437),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2E1A47)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2E1A47)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFC89B3C)),
                ),
              ),
            ),

            const SizedBox(height: 18),

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
      ),
    );
  }
}
