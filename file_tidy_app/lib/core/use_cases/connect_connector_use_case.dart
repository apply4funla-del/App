import 'package:file_tidy_app/core/interfaces/connector_auth_repository.dart';
import 'package:file_tidy_app/core/models/connector_account_state.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

class ConnectConnectorUseCase {
  const ConnectConnectorUseCase(this._repository);

  final ConnectorAuthRepository _repository;

  Future<ConnectorAccountState> call({
    required FileSource source,
    String? accountLabel,
  }) {
    return _repository.connect(
      source: source,
      accountLabel: accountLabel,
    );
  }
}
