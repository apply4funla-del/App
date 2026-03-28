class RenameRecord {
  const RenameRecord({
    required this.id,
    required this.fileId,
    required this.beforeName,
    required this.afterName,
    required this.createdAt,
  });

  final String id;
  final String fileId;
  final String beforeName;
  final String afterName;
  final DateTime createdAt;
}
