import 'package:file_tidy_app/core/interfaces/ai_rename_service.dart';

class GetAiRenameSuggestionsUseCase {
  const GetAiRenameSuggestionsUseCase(this._aiRenameService);

  final AiRenameService _aiRenameService;

  Future<List<String>> call({
    required String currentName,
    required String context,
  }) {
    return _aiRenameService.suggestNames(
      currentName: currentName,
      context: context,
    );
  }
}
