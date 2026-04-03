enum UsbArchiveFileOutcome {
  copied,
  renamedCopy,
  replacedExisting,
  failed,
}

class UsbArchiveFileResult {
  const UsbArchiveFileResult({
    required this.fileId,
    required this.fileName,
    required this.sourcePath,
    required this.destinationPath,
    required this.outcome,
    required this.verified,
  });

  final String fileId;
  final String fileName;
  final String sourcePath;
  final String destinationPath;
  final UsbArchiveFileOutcome outcome;
  final bool verified;
}

class UsbArchiveExecutionResult {
  const UsbArchiveExecutionResult({
    required this.fileResults,
    this.removedOriginalCount = 0,
  });

  final List<UsbArchiveFileResult> fileResults;
  final int removedOriginalCount;

  int get copiedCount => fileResults.where((item) => item.outcome != UsbArchiveFileOutcome.failed).length;
  int get renamedCopyCount =>
      fileResults.where((item) => item.outcome == UsbArchiveFileOutcome.renamedCopy).length;
  int get replacedCount =>
      fileResults.where((item) => item.outcome == UsbArchiveFileOutcome.replacedExisting).length;
  int get failedCount =>
      fileResults.where((item) => item.outcome == UsbArchiveFileOutcome.failed).length;
  int get verifiedCount => fileResults.where((item) => item.verified).length;

  UsbArchiveExecutionResult copyWith({
    List<UsbArchiveFileResult>? fileResults,
    int? removedOriginalCount,
  }) {
    return UsbArchiveExecutionResult(
      fileResults: fileResults ?? this.fileResults,
      removedOriginalCount: removedOriginalCount ?? this.removedOriginalCount,
    );
  }
}
