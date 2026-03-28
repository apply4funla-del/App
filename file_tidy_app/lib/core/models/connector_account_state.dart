import 'package:file_tidy_app/core/models/file_item.dart';

class ConnectorAccountState {
  const ConnectorAccountState({
    required this.source,
    required this.connected,
    this.accountLabel,
    this.connectedAt,
  });

  final FileSource source;
  final bool connected;
  final String? accountLabel;
  final DateTime? connectedAt;

  ConnectorAccountState copyWith({
    bool? connected,
    String? accountLabel,
    DateTime? connectedAt,
  }) {
    return ConnectorAccountState(
      source: source,
      connected: connected ?? this.connected,
      accountLabel: accountLabel ?? this.accountLabel,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}
