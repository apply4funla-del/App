enum UsbArchivePresetFolder {
  memoirsPhotos,
  memoirsFolders,
}

extension UsbArchivePresetFolderValue on UsbArchivePresetFolder {
  List<String> get pathSegments {
    switch (this) {
      case UsbArchivePresetFolder.memoirsPhotos:
        return const ['Memoirs', 'Photos'];
      case UsbArchivePresetFolder.memoirsFolders:
        return const ['Memoirs', 'Folders'];
    }
  }

  String get label {
    switch (this) {
      case UsbArchivePresetFolder.memoirsPhotos:
        return 'Memoirs / Photos';
      case UsbArchivePresetFolder.memoirsFolders:
        return 'Memoirs / Folders';
    }
  }
}
