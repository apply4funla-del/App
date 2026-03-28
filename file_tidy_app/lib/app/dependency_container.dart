import 'package:file_tidy_app/core/interfaces/ai_rename_service.dart';
import 'package:file_tidy_app/core/interfaces/file_repository.dart';
import 'package:file_tidy_app/data/adapters/ai/mock_ai_rename_service.dart';
import 'package:file_tidy_app/data/repositories/in_memory_file_repository.dart';

class DependencyContainer {
  DependencyContainer._();

  static final DependencyContainer instance = DependencyContainer._();

  final FileRepository fileRepository = InMemoryFileRepository();
  final AiRenameService aiRenameService = MockAiRenameService();
}
