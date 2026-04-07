// lib/views/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import 'home_view.dart';
import 'vault_view.dart';
import 'settings_view.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Column(
        children: [
          if (state.errorMessage != null)
            _NotificationBanner(
              message: state.errorMessage!,
              isError: true,
              onClose: state.clearMessages,
            ),
          if (state.successMessage != null)
            _NotificationBanner(
              message: state.successMessage!,
              isError: false,
              onClose: state.clearMessages,
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (state.currentView) {
                AppView.home     => const HomeView(),
                AppView.vault    => const VaultView(),
                AppView.settings => const SettingsView(),
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: state.currentView.index,
        onDestinationSelected: (i) => state.navigate(AppView.values[i]),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onClose;
  const _NotificationBanner({required this.message, required this.isError, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.errorContainer
        : const Color(0xFFD4EDDA);
    final textColor = isError
        ? Theme.of(context).colorScheme.onErrorContainer
        : const Color(0xFF155724);

    return Material(
      child: Container(
        width: double.infinity,
        color: color,
        padding: EdgeInsets.only(
          left: 16, right: 8, top: 10 + MediaQuery.of(context).padding.top, bottom: 10,
        ),
        child: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: textColor, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: textColor, fontSize: 13))),
            IconButton(icon: Icon(Icons.close, color: textColor, size: 18), onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
