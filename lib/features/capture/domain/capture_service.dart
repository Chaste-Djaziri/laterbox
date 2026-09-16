import '../../inbox/data/item_repository.dart';
import 'capture_payload.dart';

class CaptureService {
  const CaptureService(this._repository);

  final ItemRepository _repository;

  Future<void> save(CapturePayload payload) async {
    await saveWithResult(payload);
  }

  Future<String> saveWithResult(CapturePayload payload) {
    return _repository.save(
      payload.url ?? payload.value,
      id: payload.id,
      title: payload.title,
      type: payload.type,
      createdAt: payload.createdAt,
      returnAt: payload.returnAt,
      textContent: payload.text,
      url: payload.url,
    );
  }
}
