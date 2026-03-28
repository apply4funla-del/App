import 'package:file_tidy_app/core/interfaces/connector_auth_repository.dart';
import 'package:file_tidy_app/core/models/connector_account_state.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

class ListConnectorStatesUseCase {
  const ListConnectorStatesUseCase(this._repository);

  final ConnectorAuthRepository _repository;

  Future<Map<FileSource, ConnectorAccountState>> call() {
    return _repository.listStates();
  }
}
