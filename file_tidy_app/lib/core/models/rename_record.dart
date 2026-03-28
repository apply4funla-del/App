enum RenameActionType { renameInPlace, duplicateCreated, replaceWithDuplicate }

class RenameRecord {
  const RenameRecord({
    required this.id,
    required this.fileId,
    required this.beforeName,
    required this.afterName,
    this.sourceFileId,
    this.actionType = RenameActionType.renameInPlace,
    this.beforePath,
    this.afterPath,
    required this.createdAt,
  });

  final String id;
  final String fileId;
  final String beforeName;
  final String afterName;
  final String? sourceFileId;
  final RenameActionType actionType;
  final String? beforePath;
  final String? afterPath;
  final DateTime createdAt;
}
