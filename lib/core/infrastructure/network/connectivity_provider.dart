import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@riverpod
Stream<bool> connectivityStream(Ref ref) {
  final connectivity = Connectivity();

  return connectivity.onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
}

/// Провайдер онлайн-статуса.
/// Подписывается на [connectivityStreamProvider] и возвращает `false` при оффлайне.
@riverpod
bool isOnline(Ref ref) {
  final asyncValue = ref.watch(connectivityStreamProvider);
  // По умолчанию online (пока stream не стартовал).
  return asyncValue.valueOrNull ?? true;
}
