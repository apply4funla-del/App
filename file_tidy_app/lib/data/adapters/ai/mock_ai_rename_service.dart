import 'package:file_tidy_app/core/interfaces/ai_rename_service.dart';

class MockAiRenameService implements AiRenameService {
  @override
  Future<List<String>> suggestNames({
    required String currentName,
    required String context,
  }) async {
    final sanitized = currentName.replaceAll(' ', '_');
    return [
      '2026-03-$sanitized',
      '${context.replaceAll(' ', '_')}_$sanitized',
      '${sanitized}_clean_copy',
    ];
  }
}
