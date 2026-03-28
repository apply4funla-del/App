import 'package:file_tidy_app/core/models/connector_account_state.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

abstract class ConnectorAuthRepository {
  Future<Map<FileSource, ConnectorAccountState>> listStates();

  Future<ConnectorAccountState> connect({
    required FileSource source,
    String? accountLabel,
  });

  Future<void> disconnect(FileSource source);
}
