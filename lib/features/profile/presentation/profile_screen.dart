import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/env_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../audio_player/presentation/mini_player.dart';
import '../../downloads/presentation/download_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profile = authState.profile;
    final isGuest = authState.isGuest;

    final favoriteCount = ref.watch(favoritesControllerProvider).length;
    final downloadCount = ref.watch(downloadsControllerProvider).downloadedItems.length;

    return Scaffold(
      appBar: const GlassAppBar(title: 'គណនី និងការកំណត់'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              // User Header Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 24,
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          isGuest
                              ? 'ភ្ញៀវ'
                              : (profile?.displayName?.isNotEmpty == true
                                  ? profile!.displayName![0].toUpperCase()
                                  : 'U'),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGuest ? 'ភ្ញៀវ (Guest User)' : (profile?.displayName ?? 'អ្នកប្រើប្រាស់'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isGuest ? 'មិនទាន់បានចូលគណនី' : (user?.email ?? ''),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isGuest)
                      ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('ចូលគណនី'),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        onPressed: () => _showEditProfileDialog(context, ref, profile?.displayName ?? ''),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Listening Stats Summary Row
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      borderRadius: 18,
                      child: Column(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            '$favoriteCount',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Text('រឿងពេញចិត្ត', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      borderRadius: 18,
                      child: Column(
                        children: [
                          const Icon(Icons.download_done_rounded, color: AppColors.accentDark, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            '$downloadCount',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Text('ទាញយក', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Navigation List Options
              Text(
                'បណ្ណាល័យស្តាប់',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.favorite_border_rounded, color: AppColors.primary),
                      title: const Text('រឿងដែលបានរក្សាទុក (Favorites)'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/favorites'),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.history_rounded, color: AppColors.primary),
                      title: const Text('ប្រវត្តិនៃការស្តាប់ (History)'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/history'),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined, color: AppColors.primary),
                      title: const Text('ឯកសារទាញយក (Downloads)'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/downloads'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'ការកំណត់ទូទៅ',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                      title: const Text('ភាសា (Language)'),
                      trailing: const Text('ភាសាខ្មែរ (KM)', style: TextStyle(color: AppColors.textSecondary)),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                      title: const Text('គោលការណ៍ឯកជនភាព (Privacy Policy)'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                      title: const Text('លក្ខខណ្ឌប្រើប្រាស់ (Terms of Service)'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!isGuest) ...[
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 20,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                        title: const Text('ចាកចេញពីគណនី (Sign Out)', style: TextStyle(color: AppColors.error)),
                        onTap: () async {
                          await ref.read(authProvider.notifier).signOut();
                        },
                      ),
                      const Divider(height: 1, indent: 56, color: AppColors.outlineVariant),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                        title: const Text('លុបគណនី (Delete Account)', style: TextStyle(color: AppColors.error)),
                        onTap: () => _confirmDeleteAccount(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Version Info
              Center(
                child: Text(
                  '${AppConstants.appTitle} v${EnvConfig.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
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

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('កែប្រែព័ត៌មានគណនី'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'ឈ្មោះបង្ហាញ (Display Name)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('បោះបង់')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref.read(authProvider.notifier).updateProfile(displayName: controller.text);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('រក្សាទុក'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('លុបគណនីជាអចិន្ត្រៃយ៍?'),
        content: const Text('ទិន្នន័យ ប្រវត្តិស្តាប់ និងរឿងដែលអ្នកបានរក្សាទុកទាំងអស់ នឹងត្រូវលុបចេញពីប្រព័ន្ធទាំងស្រុង។'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).deleteAccount();
            },
            child: const Text('បញ្ជាក់ការលុប'),
          ),
        ],
      ),
    );
  }
}
