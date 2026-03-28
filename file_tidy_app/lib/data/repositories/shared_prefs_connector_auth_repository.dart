import 'dart:convert';

import 'package:file_tidy_app/core/interfaces/connector_auth_repository.dart';
import 'package:file_tidy_app/core/models/connector_account_state.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsConnectorAuthRepository implements ConnectorAuthRepository {
  static const String _key = 'connectors.state.v1';

  @override
  Future<Map<FileSource, ConnectorAccountState>> listStates() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) {
      return _defaults();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final next = <FileSource, ConnectorAccountState>{};
      for (final source in FileSource.values) {
        final sourceKey = source.name;
        final value = decoded[sourceKey];
        if (value is! Map<String, dynamic>) {
          next[source] = _defaultFor(source);
          continue;
        }
        next[source] = ConnectorAccountState(
          source: source,
          connected: value['connected'] == true,
          accountLabel: value['accountLabel'] as String?,
          connectedAt: value['connectedAt'] == null
              ? null
              : DateTime.tryParse(value['connectedAt'] as String),
        );
      }
      return next;
    } catch (_) {
      return _defaults();
    }
  }

  @override
  Future<ConnectorAccountState> connect({
    required FileSource source,
    String? accountLabel,
  }) async {
    final states = await listStates();
    final value = ConnectorAccountState(
      source: source,
      connected: true,
      accountLabel: accountLabel,
      connectedAt: DateTime.now(),
    );
    states[source] = value;
    await _save(states);
    return value;
  }

  @override
  Future<void> disconnect(FileSource source) async {
    final states = await listStates();
    states[source] = _defaultFor(source);
    await _save(states);
  }

  Future<void> _save(Map<FileSource, ConnectorAccountState> states) async {
    final payload = <String, dynamic>{};
    for (final entry in states.entries) {
      payload[entry.key.name] = {
        'connected': entry.value.connected,
        'accountLabel': entry.value.accountLabel,
        'connectedAt': entry.value.connectedAt?.toIso8601String(),
      };
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(payload));
  }

  Map<FileSource, ConnectorAccountState> _defaults() {
    return {
      for (final source in FileSource.values) source: _defaultFor(source),
    };
  }

  ConnectorAccountState _defaultFor(FileSource source) {
    if (source == FileSource.phone) {
      return ConnectorAccountState(
        source: source,
        connected: true,
        accountLabel: 'This device',
      );
    }
    return ConnectorAccountState(source: source, connected: false);
  }
}
