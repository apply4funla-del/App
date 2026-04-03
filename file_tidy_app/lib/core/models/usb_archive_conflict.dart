class UsbArchiveConflict {
  const UsbArchiveConflict({
    required this.sourceName,
    required this.existingPath,
    required this.suggestedName,
  });

  final String sourceName;
  final String existingPath;
  final String suggestedName;
}
