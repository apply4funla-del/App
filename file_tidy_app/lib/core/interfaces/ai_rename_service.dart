abstract class AiRenameService {
  Future<List<String>> suggestNames({
    required String currentName,
    required String context,
  });
}
