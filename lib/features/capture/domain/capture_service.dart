import '../../inbox/data/item_repository.dart';
import 'capture_payload.dart';

class CaptureService {
  const CaptureService(this._repository);

  final ItemRepository _repository;

  Future<void> save(CapturePayload payload) {
    return _repository.save(payload.value);
  }
}