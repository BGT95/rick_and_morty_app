import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../infrastructure/network/connectivity_provider.dart';

/// Тонкий баннер сверху экрана, показывающий «Нет подключения к сети»,
/// когда устройство оффлайн. Автоматически скрывается при восстановлении сети.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) return const SizedBox.shrink();

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.wifi_off, color: Colors.white),
      content: const Text(
        'Нет подключения к сети',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red.shade700,
      actions: const [SizedBox.shrink()],
    );
  }
}
