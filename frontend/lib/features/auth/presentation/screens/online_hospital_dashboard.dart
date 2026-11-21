import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/auth/online_hospital_session.dart';
import 'package:hospital_management/core/router/app_routes.dart';

class OnlineHospitalDashboardScreen extends ConsumerWidget {
  const OnlineHospitalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(onlineHospitalSessionProvider);
    final hospital = session.hospital;
    final user = session.user;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(hospital?.name ?? 'Hospital dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh server session',
            onPressed: session.isLoading ? null : () => ref.read(onlineHospitalSessionProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              final serverRevoked = await ref.read(onlineHospitalSessionProvider.notifier).logout();
              if (!context.mounted) return;
              context.go(AppRoutes.login);
              if (!serverRevoked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out locally; the server could not confirm token revocation.')),
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: session.isLoading || session.isRestoring
                  ? const CircularProgressIndicator()
                  : hospital == null || user == null
                      ? _buildError(context, ref, session.error, colors)
                      : _buildHospitalContent(context, hospital, user, colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalContent(BuildContext context, OnlineHospitalProfile hospital,
      OnlineHospitalUser user, ColorScheme colors) {
    return ListView(
      shrinkWrap: true,
      children: [
        Icon(Icons.local_hospital_outlined, size: 64, color: colors.primary),
        const SizedBox(height: 16),
        Text(hospital.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        Text('${hospital.type} · ${hospital.code}', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verified Hospital account', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('Hospital ID: ${hospital.hospitalId}'),
                Text('Signed in as: ${user.fullName} (${user.username})'),
                Text('Role: ${user.role}'),
                if (hospital.address?.isNotEmpty == true) Text('Address: ${hospital.address}'),
                if (hospital.email?.isNotEmpty == true) Text('Email: ${hospital.email}'),
                if (hospital.phone?.isNotEmpty == true) Text('Phone: ${hospital.phone}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Your online session is scoped to this approved Hospital. Clinical modules will appear here as their server APIs are integrated.'),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.onlineClinical),
          icon: const Icon(Icons.cloud_queue),
          label: const Text('Open online clinical workspace'),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String? error, ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_outlined, color: colors.error, size: 48),
        const SizedBox(height: 12),
        Text(error ?? 'The Hospital profile could not be loaded.', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => ref.read(onlineHospitalSessionProvider.notifier).refresh(),
          child: const Text('Try again'),
        ),
        TextButton(
          onPressed: () => ref.read(onlineHospitalSessionProvider.notifier).logout(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
