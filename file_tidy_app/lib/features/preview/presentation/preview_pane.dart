import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:xml/xml.dart';

class PreviewPane extends StatelessWidget {
  const PreviewPane({
    super.key,
    required this.item,
  });

  final FileItem? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const Center(
        child: Text('Select a file to preview.'),
      );
    }

    if (item!.type == FileItemType.folder) {
      return const Center(
        child: Text('Folder selected. Choose a file to preview content.'),
      );
    }

    if (item!.type == FileItemType.pdf && item!.path != null) {
      final file = File(item!.path!);
      if (file.existsSync()) {
        return SfPdfViewer.file(file);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item!.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Source: ${item!.source.label}'),
              const SizedBox(height: AppSpacing.xs),
              Text('Type: ${item!.type.name}'),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (item?.path == null) {
      return const Center(
        child: Text(
          'Preview placeholder.\nImport a local file for live content preview.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final file = File(item!.path!);
    if (!file.existsSync()) {
      return const Center(
        child: Text('File path is unavailable on this device.'),
      );
    }

    if (item!.type == FileItemType.image) {
      return _imagePreview(file);
    }

    if (_looksLikeImagePath(item!.path!)) {
      return _imagePreview(file);
    }

    final extension = _fileExtension(item!.path!);
    if (_isOfficeOpenXml(extension)) {
      return _officePreview(file, extension);
    }

    if (_isLegacyOfficeBinary(extension)) {
      return const Center(
        child: Text(
          'Legacy Office file preview is limited.\nUse docx/xlsx/pptx for in-app content preview.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (item!.type == FileItemType.text || item!.type == FileItemType.document) {
      return FutureBuilder<String>(
        future: file.readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to read this text content.'),
            );
          }
          final content = snapshot.data ?? '';
          final preview = content.length > 5000 ? '${content.substring(0, 5000)}\n...' : content;
          return SingleChildScrollView(
            child: Text(preview),
          );
        },
      );
    }

    return const Center(
      child: Text('Preview available after provider connector integration.'),
    );
  }

  Widget _officePreview(File file, String extension) {
    return FutureBuilder<String>(
      future: _extractOfficePreview(file, extension),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to preview this Office file.'),
          );
        }
        final text = snapshot.data?.trim() ?? '';
        if (text.isEmpty) {
          return const Center(
            child: Text('No readable text found in this file.'),
          );
        }
        final preview = text.length > 9000 ? '${text.substring(0, 9000)}\n...' : text;
        return SingleChildScrollView(
          child: Text(preview),
        );
      },
    );
  }

  Widget _imagePreview(File file) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Unable to load this image preview.'),
          );
        }
        return InteractiveViewer(
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) => const Center(
              child: Text('This image format is not supported for preview.'),
            ),
          ),
        );
      },
    );
  }

  bool _looksLikeImagePath(String path) {
    final extension = _fileExtension(path);
    return {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'heif',
      'gif',
      'bmp',
      'tif',
      'tiff',
      'dng',
    }.contains(extension);
  }

  bool _isOfficeOpenXml(String extension) {
    return {'docx', 'xlsx', 'pptx'}.contains(extension);
  }

  bool _isLegacyOfficeBinary(String extension) {
    return {'doc', 'xls', 'ppt'}.contains(extension);
  }

  String _fileExtension(String path) {
    final value = path.trim().toLowerCase();
    final dotIndex = value.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == value.length - 1) {
      return '';
    }
    return value.substring(dotIndex + 1);
  }

  Future<String> _extractOfficePreview(File file, String extension) async {
    final bytes = await file.readAsBytes();
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (_) {
      return '';
    }

    if (extension == 'docx') {
      return _extractDocxText(archive);
    }
    if (extension == 'pptx') {
      return _extractPptxText(archive);
    }
    if (extension == 'xlsx') {
      return _extractXlsxText(archive);
    }
    return '';
  }

  String _extractDocxText(Archive archive) {
    final xmlText = _readArchiveText(archive, 'word/document.xml');
    if (xmlText == null || xmlText.isEmpty) {
      return '';
    }

    XmlDocument document;
    try {
      document = XmlDocument.parse(xmlText);
    } catch (_) {
      return '';
    }

    final lines = <String>[];
    for (final paragraph in document.descendants.whereType<XmlElement>()) {
      if (paragraph.name.local != 'p') {
        continue;
      }
      final textParts = <String>[];
      for (final value in paragraph.descendants.whereType<XmlElement>()) {
        if (value.name.local == 't') {
          final text = value.innerText.trim();
          if (text.isNotEmpty) {
            textParts.add(text);
          }
        }
      }
      if (textParts.isNotEmpty) {
        lines.add(textParts.join(' '));
      }
      if (lines.length >= 120) {
        break;
      }
    }
    return lines.join('\n');
  }

  String _extractPptxText(Archive archive) {
    final slideEntries = archive.files
        .where((entry) => entry.name.startsWith('ppt/slides/slide') && entry.name.endsWith('.xml'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (slideEntries.isEmpty) {
      return '';
    }

    final output = <String>[];
    for (var index = 0; index < slideEntries.length; index++) {
      final xmlText = utf8.decode(slideEntries[index].content, allowMalformed: true);
      XmlDocument document;
      try {
        document = XmlDocument.parse(xmlText);
      } catch (_) {
        continue;
      }
      final textParts = <String>[];
      for (final value in document.descendants.whereType<XmlElement>()) {
        if (value.name.local == 't') {
          final text = value.innerText.trim();
          if (text.isNotEmpty) {
            textParts.add(text);
          }
        }
      }
      if (textParts.isNotEmpty) {
        output.add('Slide ${index + 1}');
        output.add(textParts.join(' | '));
        output.add('');
      }
      if (output.length > 220) {
        break;
      }
    }
    return output.join('\n').trim();
  }

  String _extractXlsxText(Archive archive) {
    final sharedStrings = _extractSharedStrings(archive);
    final sheetEntries = archive.files
        .where(
          (entry) =>
              entry.name.startsWith('xl/worksheets/sheet') &&
              entry.name.endsWith('.xml'),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (sheetEntries.isEmpty) {
      return '';
    }

    final output = <String>[];
    for (var sheetIndex = 0; sheetIndex < sheetEntries.length; sheetIndex++) {
      final entry = sheetEntries[sheetIndex];
      XmlDocument document;
      try {
        document = XmlDocument.parse(utf8.decode(entry.content, allowMalformed: true));
      } catch (_) {
        continue;
      }
      output.add('Sheet ${sheetIndex + 1}');

      var rowCount = 0;
      for (final row in document.descendants.whereType<XmlElement>()) {
        if (row.name.local != 'row') {
          continue;
        }
        final parts = <String>[];
        for (final cell in row.children.whereType<XmlElement>()) {
          if (cell.name.local != 'c') {
            continue;
          }
          final cellRef = cell.getAttribute('r') ?? '';
          final type = cell.getAttribute('t') ?? '';
          final value = _xlsxCellValue(cell, type, sharedStrings);
          if (value.isEmpty) {
            continue;
          }
          parts.add(cellRef.isEmpty ? value : '$cellRef: $value');
          if (parts.length >= 10) {
            break;
          }
        }
        if (parts.isNotEmpty) {
          output.add(parts.join(' | '));
          rowCount += 1;
        }
        if (rowCount >= 25) {
          break;
        }
      }
      output.add('');
      if (output.length > 280) {
        break;
      }
    }

    return output.join('\n').trim();
  }

  List<String> _extractSharedStrings(Archive archive) {
    final xmlText = _readArchiveText(archive, 'xl/sharedStrings.xml');
    if (xmlText == null || xmlText.isEmpty) {
      return const [];
    }
    XmlDocument document;
    try {
      document = XmlDocument.parse(xmlText);
    } catch (_) {
      return const [];
    }
    final strings = <String>[];
    for (final node in document.descendants.whereType<XmlElement>()) {
      if (node.name.local != 'si') {
        continue;
      }
      final textParts = <String>[];
      for (final value in node.descendants.whereType<XmlElement>()) {
        if (value.name.local == 't') {
          final text = value.innerText;
          if (text.isNotEmpty) {
            textParts.add(text);
          }
        }
      }
      strings.add(textParts.join());
    }
    return strings;
  }

  String _xlsxCellValue(XmlElement cell, String type, List<String> sharedStrings) {
    if (type == 'inlineStr') {
      for (final node in cell.descendants.whereType<XmlElement>()) {
        if (node.name.local == 't') {
          final text = node.innerText.trim();
          if (text.isNotEmpty) {
            return text;
          }
        }
      }
      return '';
    }

    String rawValue = '';
    for (final node in cell.children.whereType<XmlElement>()) {
      if (node.name.local == 'v') {
        rawValue = node.innerText.trim();
        break;
      }
    }
    if (rawValue.isEmpty) {
      return '';
    }
    if (type == 's') {
      final sharedIndex = int.tryParse(rawValue);
      if (sharedIndex == null || sharedIndex < 0 || sharedIndex >= sharedStrings.length) {
        return rawValue;
      }
      return sharedStrings[sharedIndex].trim();
    }
    return rawValue;
  }

  String? _readArchiveText(Archive archive, String path) {
    final entry = archive.findFile(path);
    if (entry == null) {
      return null;
    }
    return utf8.decode(entry.content, allowMalformed: true);
  }
}
