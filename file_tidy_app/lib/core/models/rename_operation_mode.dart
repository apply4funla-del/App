enum RenameOperationMode { workInPlace, duplicate }

extension RenameOperationModeLabel on RenameOperationMode {
  String get label {
    switch (this) {
      case RenameOperationMode.workInPlace:
        return 'Work In Place';
      case RenameOperationMode.duplicate:
        return 'Duplicate';
    }
  }
}
