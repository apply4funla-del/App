enum UsbArchiveRetentionMode {
  keepOnPhone,
  removeFromPhone,
}

extension UsbArchiveRetentionModeLabel on UsbArchiveRetentionMode {
  String get label {
    switch (this) {
      case UsbArchiveRetentionMode.keepOnPhone:
        return 'Archive and Keep on Phone';
      case UsbArchiveRetentionMode.removeFromPhone:
        return 'Archive and Remove from Phone';
    }
  }

  String get helperText {
    switch (this) {
      case UsbArchiveRetentionMode.keepOnPhone:
        return 'Creates a USB copy and leaves the original file on the phone.';
      case UsbArchiveRetentionMode.removeFromPhone:
        return 'Creates a USB copy, checks it, then removes the original from the phone.';
    }
  }
}
