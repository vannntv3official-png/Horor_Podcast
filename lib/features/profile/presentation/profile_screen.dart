import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/env_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../audio_player/presentation/mini_player.dart';
import '../../audio_player/presentation/player_controller.dart';
import '../../downloads/presentation/download_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../../history/presentation/history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _audioQuality = 'ស្តង់ដារ (128 kbps)';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profile = authState.profile;
    final isGuest = authState.isGuest;

    final favoriteCount = ref.watch(favoritesControllerProvider).length;
    final downloadsState = ref.watch(downloadsControllerProvider);
    final downloadCount = downloadsState.downloadedItems.length;
    final downloadSize = Formatters.formatFileSize(downloadsState.totalStorageBytes);

    final historyAsync = ref.watch(listeningHistoryProvider);
    final historyCount = historyAsync.valueOrNull?.length ?? 0;

    final currentSpeed = ref.watch(playerControllerProvider).speed;

    return Scaffold(
      appBar: const GlassAppBar(title: 'គណនី និងការកំណត់'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              // 1. User Header Profile Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 24,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accentDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isGuest
                                  ? 'ភ្ញៀវ'
                                  : (profile?.displayName?.isNotEmpty == true
                                      ? profile!.displayName![0].toUpperCase()
                                      : (user?.email?.isNotEmpty == true
                                          ? user!.email![0].toUpperCase()
                                          : 'U')),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name & Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      isGuest
                                          ? 'ភ្ញៀវ (Guest User)'
                                          : (profile?.displayName?.isNotEmpty == true
                                              ? profile!.displayName!
                                              : 'អ្នកប្រើប្រាស់'),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isGuest) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded, size: 18, color: AppColors.accent),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isGuest ? 'មិនទាន់បានចូលគណនី' : (user?.email ?? ''),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isGuest
                                      ? AppColors.secondaryLight
                                      : AppColors.primaryContainer.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isGuest
                                        ? AppColors.outlineVariant
                                        : AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  isGuest ? 'គណនីភ្ញៀវ' : 'សមាជិកផ្លូវការ (Member)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isGuest ? AppColors.textTertiary : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Button
                        if (isGuest)
                          ElevatedButton(
                            onPressed: () => context.push('/login'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('ចូលគណនី'),
                          )
                        else
                          IconButton.filledTonal(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showEditProfileDialog(
                              context,
                              profile?.displayName ?? '',
                            ),
                          ),
                      ],
                    ),

                    if (isGuest) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'ចូលគណនីដើម្បីកុំឱ្យបាត់បង់រឿងពេញចិត្ត និងប្រវត្តិស្តាប់ពេលប្តូរទូរស័ព្ទ។',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Interactive Stats Row (3 Quick Action Cards)
              Row(
                children: [
                  // Favorites
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/favorites'),
                      borderRadius: BorderRadius.circular(20),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        borderRadius: 20,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$favoriteCount',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Text('រឿងពេញចិត្ត', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // History
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/history'),
                      borderRadius: BorderRadius.circular(20),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        borderRadius: 20,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_rounded, color: Colors.amber, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$historyCount',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Text('ប្រវត្តិស្តាប់', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Downloads
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/downloads'),
                      borderRadius: BorderRadius.circular(20),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        borderRadius: 20,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentDark.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_done_rounded, color: AppColors.accentDark, size: 22),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$downloadCount',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              downloadCount > 0 ? downloadSize : 'ទាញយក',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Audio & Playback Preferences
              Text(
                'ការកំណត់សំឡេង និងការចាក់',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.speed_rounded, color: AppColors.primary),
                      title: const Text('ល្បឿនចាក់សំឡេង (Playback Speed)'),
                      subtitle: Text(
                        'បច្ចុប្បន្ន៖ ${currentSpeed}x',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showSpeedSelectorDialog(context, currentSpeed),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.high_quality_rounded, color: AppColors.primary),
                      title: const Text('គុណភាពចាក់សំឡេង (Streaming Quality)'),
                      subtitle: Text(
                        _audioQuality,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showAudioQualityDialog(context),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.bedtime_outlined, color: AppColors.primary),
                      title: const Text('កំណត់ម៉ោងគេង (Sleep Timer)'),
                      subtitle: const Text(
                        'បិទសំឡេងដោយស្វ័យប្រវត្តិពេលគេងលក់',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showSleepTimerDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Storage & Cache Management
              Text(
                'ការគ្រប់គ្រងទិន្នន័យ (Storage & Cache)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.folder_open_rounded, color: AppColors.primary),
                      title: const Text('ឯកសារទាញយកទាំងអស់ (Downloads)'),
                      subtitle: Text(
                        '$downloadCount ភាគ ($downloadSize)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/downloads'),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.primary),
                      title: const Text('សម្អាត Cache (Clear App Cache)'),
                      subtitle: const Text(
                        'សម្អាតរូបភាព និងទិន្នន័យបណ្តោះអាសន្នដើម្បីបង្កើនទំហំទូរស័ព្ទ',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.delete_sweep_rounded),
                      onTap: () => _clearAppCache(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Information & Support
              Text(
                'ព័ត៌មាន និងការគាំទ្រ (Info & Support)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                      title: const Text('ទាក់ទងក្រុមការងារ (Contact Support)'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showContactSupportDialog(context),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.share_rounded, color: AppColors.primary),
                      title: const Text('ចែករំលែកកម្មវិធីទៅកាន់មិត្តភក្តិ'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _shareApp(context),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                      title: const Text('គោលការណ៍ឯកជនភាព (Privacy Policy)'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _showPrivacyPolicyDialog(context),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                      title: const Text('លក្ខខណ្ឌប្រើប្រាស់ (Terms of Service)'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _showTermsDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Account Danger Zone (Sign Out & Delete)
              if (!isGuest) ...[
                Text(
                  'គណនី (Account)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 20,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: Colors.orangeAccent),
                        title: const Text('ចាកចេញពីគណនី (Sign Out)', style: TextStyle(color: Colors.orangeAccent)),
                        subtitle: const Text('ចាកចេញពីគណនីលើឧបករណ៍នេះ', style: TextStyle(fontSize: 12)),
                        onTap: () => _confirmSignOut(context),
                      ),
                      const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                        title: const Text('លុបគណនី (Delete Account)', style: TextStyle(color: AppColors.error)),
                        subtitle: const Text('លុបគណនី និងទិន្នន័យជាអចិន្ត្រៃយ៍', style: TextStyle(fontSize: 12)),
                        onTap: () => _confirmDeleteAccount(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 7. App Branding & Version Footer
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 48,
                        height: 48,
                        errorBuilder: (_, __, ___) => const Icon(Icons.headphones_rounded, size: 40, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ជំនាន់ Version ${EnvConfig.appVersion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppConstants.appTagline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'រក្សាសិទ្ធិគ្រប់យ៉ាង ២០២៦ © Khmer Horror Podcast',
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Docked MiniPlayer
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  // --- Dialogs & Bottom Sheets ---

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('កែប្រែព័ត៌មានគណនី'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'បញ្ចូលឈ្មោះដែលអ្នកចង់ឱ្យបង្ហាញនៅក្នុង App៖',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'ឈ្មោះបង្ហាញ (Display Name)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(ctx).pop();
                final ok = await ref.read(authProvider.notifier).updateProfile(displayName: newName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'ឈ្មោះត្រូវបានកែប្រែជោគជ័យ!' : 'ការកែប្រែបរាជ័យ សូមព្យាយាមម្តងទៀត'),
                      backgroundColor: ok ? AppColors.accentDark : AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('រក្សាទុក'),
          ),
        ],
      ),
    );
  }

  void _showSpeedSelectorDialog(BuildContext context, double currentSpeed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ជ្រើសរើសល្បឿនចាក់សំឡេង (Playback Speed)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.playbackSpeeds.map((speed) {
                  final isSelected = (speed - currentSpeed).abs() < 0.01;
                  return ChoiceChip(
                    label: Text('${speed}x', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(playerControllerProvider.notifier).setSpeed(speed);
                        ref.read(localStorageProvider).savePlaybackSpeed(speed);
                        Navigator.of(ctx).pop();
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAudioQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('ជ្រើសរើសគុណភាពសំឡេង'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _audioQuality = 'ស្តង់ដារ (128 kbps)');
              Navigator.of(ctx).pop();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.music_note_rounded, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text('ស្តង់ដារ (128 kbps) - សន្សំសំចៃអ៊ីនធឺណិត'),
                ],
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _audioQuality = 'ច្បាស់កម្រិតខ្ពស់ HD (320 kbps)');
              Navigator.of(ctx).pop();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.hd_rounded, color: AppColors.accent),
                  SizedBox(width: 12),
                  Text('ច្បាស់កម្រិតខ្ពស់ HD (320 kbps)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'កំណត់ម៉ោងគេង (Sleep Timer)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'សំឡេងនឹងត្រូវបានផ្អាកដោយស្វ័យប្រវត្តិតាមនាទីដែលបានជ្រើសរើស',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  ...AppConstants.sleepTimerMinutes.map((minutes) {
                    return ActionChip(
                      avatar: const Icon(Icons.timer_outlined, size: 18),
                      label: Text('$minutes នាទី'),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).setSleepTimerMinutes(minutes);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('បានកំណត់ម៉ោងគេង៖ $minutes នាទី'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                    label: const Text('បិទ Timer'),
                    onPressed: () {
                      ref.read(playerControllerProvider.notifier).cancelSleepTimer();
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('បានបិទម៉ោងគេងរួចរាល់')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _clearAppCache(BuildContext context) async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await ref.read(localStorageProvider).clearRecentSearches();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បានសម្អាត Cache និងទិន្នន័យបណ្តោះអាសន្នជោគជ័យ!'),
            backgroundColor: AppColors.accentDark,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('មានបញ្ហា៖ $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('ទាក់ទងក្រុមការងារ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ប្រសិនបើលោកអ្នកមានចម្ងល់ មានរឿងខ្មោចចង់ចែករំលែក ឬជួបបញ្ហាបច្ចេកទេស សូមទាក់ទងមកកាន់យើងខ្ញុំ៖',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.send_rounded, color: Colors.blueAccent),
              title: const Text('Telegram Channel'),
              subtitle: const Text('@KhmerHorrorPodcast'),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: '@KhmerHorrorPodcast'));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('បានចម្លង @KhmerHorrorPodcast រួចរាល់')),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.email_outlined, color: Colors.redAccent),
              title: const Text('Email ជំនួយការ'),
              subtitle: const Text('support@khmerhorrorpodcast.com'),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'support@khmerhorrorpodcast.com'));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('បានចម្លង Email រួចរាល់')),
                );
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('យល់ព្រម'),
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(
        text: 'ទាញយក Khmer Horror Podcast ស្តាប់រឿងខ្មោច និងរឿងព្រេងបុរាណខ្មែរគ្រប់រសជាតិឥតគិតថ្លៃ! https://khmerhorrorpodcast.com',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('បានចម្លងតំណភ្ជាប់ចែករំលែកកម្មវិធីទៅកាន់ Clipboard រួចរាល់!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('គោលការណ៍ឯកជនភាព'),
        content: const SingleChildScrollView(
          child: Text(
            'កម្មវិធី Khmer Horror Podcast ផ្តល់អាទិភាពខ្ពស់បំផុតលើសុវត្ថិភាព និងឯកជនភាពរបស់អ្នកប្រើប្រាស់។\n\n'
            '១. ទិន្នន័យដែលយើងប្រមូល៖ អ៊ីមែល ឈ្មោះបង្ហាញ និងប្រវត្តិស្តាប់ ដើម្បីសម្រួលដល់ការចាក់បន្ត និងរក្សាទុករឿងពេញចិត្ត។\n\n'
            '២. សុវត្ថិភាពទិន្នន័យ៖ ទិន្នន័យទាំងអស់ត្រូវបានការពារដោយប្រព័ន្ធសុវត្ថិភាពកម្រិតខ្ពស់ (Encryption) និងមិនត្រូវបានលក់ ឬចែករំលែកទៅកាន់ភាគីទីបីឡើយ។\n\n'
            '៣. សិទ្ធិអ្នកប្រើប្រាស់៖ លោកអ្នកមានសិទ្ធិកែប្រែ ឬលុបគណនី និងទិន្នន័យរបស់ខ្លួនគ្រប់ពេលវេលា។',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('យល់ព្រម')),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('លក្ខខណ្ឌប្រើប្រាស់'),
        content: const SingleChildScrollView(
          child: Text(
            'សូមស្វាគមន៍មកកាន់ Khmer Horror Podcast។ ការប្រើប្រាស់កម្មវិធីនេះ បង្ហាញពីការយល់ព្រមរបស់អ្នកលើលក្ខខណ្ឌដូចខាងក្រោម៖\n\n'
            '១. កម្មសិទ្ធិបញ្ញា៖ រាល់សំឡេងនិទាន រូបភាព និងខ្លឹមសាររឿង គឺជាកម្មសិទ្ធិរបស់ Khmer Horror Podcast និងអ្នកនិពន្ធដើម។ ហាមចម្លង ឬធ្វើពាណិជ្ជកម្មដោយគ្មានការអនុញ្ញាត។\n\n'
            '២. ការប្រើប្រាស់ដោយឥតគិតថ្លៃ៖ អ្នកប្រើប្រាស់អាចស្តាប់ និងទាញយកស្តាប់ Offline សម្រាប់គោលបំណងកម្សាន្តផ្ទាល់ខ្លួន។\n\n'
            '៣. ការទទួលខុសត្រូវ៖ ខ្លឹមសាររឿងខ្មោចខ្លះមានសភាពរន្ធត់ សូមមេត្តាពិចារណាមុនពេលស្តាប់ ជាពិសេសកុមារតូចៗ។',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('យល់ព្រម')),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('ចាកចេញពីគណនី?'),
        content: const Text(
          'តើអ្នកពិតជាចង់ចាកចេញពីគណនីមែនទេ? អ្នកអាចចូលមកកាន់គណនីនេះវិញគ្រប់ពេលវេលា។',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(localStorageProvider).setHasSeenOnboarding(true);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('ចាកចេញ'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('លុបគណនីជាអចិន្ត្រៃយ៍?'),
        content: const Text(
          'តើអ្នកប្រាកដជាចង់លុបគណនីនេះមែនទេ? ទិន្នន័យ ប្រវត្តិស្តាប់ និងរឿងដែលអ្នកបានរក្សាទុកទាំងអស់ នឹងត្រូវលុបចេញពីប្រព័ន្ធទាំងស្រុង ដោយមិនអាចទាញយកមកវិញបានឡើយ។',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(localStorageProvider).setHasSeenOnboarding(true);
              await ref.read(authProvider.notifier).deleteAccount();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('បញ្ជាក់ការលុប'),
          ),
        ],
      ),
    );
  }
}
