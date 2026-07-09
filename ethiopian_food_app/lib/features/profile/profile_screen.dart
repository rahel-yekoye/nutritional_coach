import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/providers/auth_provider.dart';
import 'package:ethiopian_food_app/core/providers/profile_provider.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';
import 'package:ethiopian_food_app/services/auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _avatarController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final authService = ref.read(authServiceProvider);
    _nameController = TextEditingController(text: authService.currentUser?.fullName ?? '');
    _avatarController = TextEditingController(text: '🙂'); // Default avatar
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges(AuthService authService, UserProfile? profile) async {
    // For now, we just update the local profile since the backend doesn't have these methods yet
    if (profile != null) {
      final updated = profile.copyWith(updatedAt: DateTime.now());
      await ref.read(profileProvider.notifier).updateProfile(updated);
    }

    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Theme',
            onPressed: () {
              final nextMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).state = nextMode;
              ref.read(sharedPreferencesProvider).setBool('isDarkMode', nextMode == ThemeMode.dark);
            },
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/');
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildAccountCard(context, currentUser, profile, authService),
              const SizedBox(height: 16),
              if (profile != null) ...[
                _buildSnapshotCard(context, profile),
                const SizedBox(height: 16),
                _buildDetailsCard(context, profile),
              ] else
                _buildEmptyProfileCard(context),
              const SizedBox(height: 16),
              _buildSettingsCard(context, themeMode, authService),
              const SizedBox(height: 16),
              _buildActionsCard(context, profile),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load profile: $error')),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, dynamic currentUser, UserProfile? profile, AuthService authService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                  child: Text(_avatarController.text.isNotEmpty ? _avatarController.text : '🙂', style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_editing)
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Display name', isDense: true),
                        )
                      else
                        Text(
                          currentUser?.fullName ?? 'Your account',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.email ?? 'Signed in',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_editing)
              TextField(
                controller: _avatarController,
                decoration: const InputDecoration(labelText: 'Avatar emoji', hintText: '🙂', isDense: true),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: profile == null ? Colors.orange.shade50 : Colors.green.shade50,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(profile == null ? Icons.pending_actions_rounded : Icons.verified_rounded, size: 16, color: profile == null ? Colors.orange.shade700 : Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(profile == null ? 'Profile setup pending' : 'Profile ready', style: TextStyle(color: profile == null ? Colors.orange.shade800 : Colors.green.shade800, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_editing)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _saveProfileChanges(authService, profile),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _editing = true),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Edit profile'),
                    ),
                  ),
                if (_editing) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _editing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotCard(BuildContext context, UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nutrition snapshot', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _metricChip(context, 'BMI', '${profile.bmi.toStringAsFixed(1)}'),
              _metricChip(context, 'BMR', '${profile.bmr.toStringAsFixed(0)} kcal'),
              _metricChip(context, 'TDEE', '${profile.tdee.toStringAsFixed(0)} kcal'),
              _metricChip(context, 'Goal', profile.goal.displayName),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow(context, 'Age', '${profile.age} years'),
            _detailRow(context, 'Gender', profile.gender.displayName),
            _detailRow(context, 'Height', '${profile.height.toStringAsFixed(0)} cm'),
            _detailRow(context, 'Weight', '${profile.weight.toStringAsFixed(0)} kg'),
            _detailRow(context, 'Activity', profile.activityLevel.displayName),
            _detailRow(context, 'Blood group', profile.bloodGroup.displayName),
            _detailRow(context, 'Fasting mode', profile.fastingMode ? 'On' : 'Off'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Build your nutrition profile', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add your goals, measurements, and blood group so the app can personalize recommendations for you.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => context.push('/onboarding'), icon: const Icon(Icons.tune_rounded), label: const Text('Create profile')),
        ]),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, ThemeMode themeMode, AuthService authService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Account settings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              final nextMode = value ? ThemeMode.dark : ThemeMode.light;
              ref.read(themeModeProvider.notifier).state = nextMode;
              ref.read(sharedPreferencesProvider).setBool('isDarkMode', value);
            },
            title: const Text('Dark mode'),
            subtitle: const Text('Use a darker UI for evening sessions'),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(authService.currentUser?.email ?? 'Signed in'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Profile status'),
            subtitle: Text(authService.currentUser?.hasCompletedSetup == true ? 'Completed' : 'In progress'),
          ),
        ]),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, UserProfile? profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quick actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => context.push('/onboarding'), icon: const Icon(Icons.edit_note_rounded), label: const Text('Manage profile'))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.go('/dashboard'), icon: const Icon(Icons.dashboard_customize_rounded), label: const Text('Go to dashboard'))),
        ]),
      ),
    );
  }

  Widget _metricChip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
