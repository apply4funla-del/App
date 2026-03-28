import 'package:file_tidy_app/core/interfaces/connector_auth_repository.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

class DisconnectConnectorUseCase {
  const DisconnectConnectorUseCase(this._repository);

  final ConnectorAuthRepository _repository;

  Future<void> call(FileSource source) {
    return _repository.disconnect(source);
  }
}
