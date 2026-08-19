import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/models/laterbox_item.dart';

class ItemRepository {
  ItemRepository(this._database, {this._uuid = const Uuid()});

  final AppDatabase _database;
  final Uuid _uuid;

  Stream<List<LaterBoxItem>> watchInboxItems() {
    return _database.watchInboxItems().map(
      (rows) => rows
          .map(
            (row) => LaterBoxItem(
              id: row.id,
              url: row.url,
              title: row.title,
              text: row.textContent,
              type: row.type,
              favorite: row.favorite,
              archived: row.archived,
              createdAt: row.createdAt,
            ),
          )
          .toList(),
    );
  }

  Future<void> save(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Paste a URL or some text to save.');
    }

    final uri = Uri.tryParse(normalized);
    final isUrl = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    final now = DateTime.now();

    await _database.saveItem(
      ItemsCompanion.insert(
        id: _uuid.v4(),
        url: Value(isUrl ? normalized : null),
        textContent: Value(isUrl ? null : normalized),
        type: Value(isUrl ? 'link' : 'text'),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
