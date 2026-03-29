import 'dart:io';

import 'package:file_tidy_app/core/interfaces/storage_permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerStoragePermissionAdapter implements StoragePermissionService {
  @override
  Future<bool> ensurePhoneReadAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final targets = <Permission>[
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ];

    for (final permission in targets) {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }
    }

    final statuses = await targets.request();
    return statuses.values.any((status) => status.isGranted || status.isLimited);
  }
}
