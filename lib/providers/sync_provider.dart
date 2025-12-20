import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';
import 'auth_provider.dart';

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.read(apiClientProvider),
    ref.read(sessionStorageProvider),
  ),
);
