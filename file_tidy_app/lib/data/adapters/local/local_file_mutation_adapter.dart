import 'dart:io';

import 'package:file_tidy_app/core/interfaces/local_file_mutation_service.dart';

class LocalFileMutationAdapter implements LocalFileMutationService {
  @override
  Future<int> deleteFiles(List<String> paths) async {
    var deleted = 0;
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      try {
        await file.delete();
        deleted += 1;
      } catch (_) {
        // Skip and continue so one failure does not stop the archive cleanup.
      }
    }
    return deleted;
  }
}
