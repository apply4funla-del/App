enum UsbArchiveConflictResolution {
  keepBoth,
  replaceExisting,
}

extension UsbArchiveConflictResolutionLabel on UsbArchiveConflictResolution {
  String get label {
    switch (this) {
      case UsbArchiveConflictResolution.keepBoth:
        return 'Keep both files';
      case UsbArchiveConflictResolution.replaceExisting:
        return 'Replace old file';
    }
  }

  String get helperText {
    switch (this) {
      case UsbArchiveConflictResolution.keepBoth:
        return 'Archive a new copy and add - 1, - 2, and so on when names match.';
      case UsbArchiveConflictResolution.replaceExisting:
        return 'Replace the file that is already on the USB drive.';
    }
  }
}
