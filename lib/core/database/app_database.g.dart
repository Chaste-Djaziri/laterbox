// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textSelectorMeta = const VerificationMeta(
    'textSelector',
  );
  @override
  late final GeneratedColumn<String> textSelector = GeneratedColumn<String>(
    'text_selector',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('inbox'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    url,
    title,
    textContent,
    textSelector,
    type,
    favorite,
    status,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('text_content')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(
          data['text_content']!,
          _textContentMeta,
        ),
      );
    }
    if (data.containsKey('text_selector')) {
      context.handle(
        _textSelectorMeta,
        textSelector.isAcceptableOrUnknown(
          data['text_selector']!,
          _textSelectorMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_content'],
      ),
      textSelector: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_selector'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final String id;
  final String? userId;
  final String? url;
  final String? title;
  final String? textContent;
  final String? textSelector;
  final String type;
  final bool favorite;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final DateTime? lastSyncedAt;
  final DateTime? deletedAt;
  const Item({
    required this.id,
    this.userId,
    this.url,
    this.title,
    this.textContent,
    this.textSelector,
    required this.type,
    required this.favorite,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || textContent != null) {
      map['text_content'] = Variable<String>(textContent);
    }
    if (!nullToAbsent || textSelector != null) {
      map['text_selector'] = Variable<String>(textSelector);
    }
    map['type'] = Variable<String>(type);
    map['favorite'] = Variable<bool>(favorite);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      textContent: textContent == null && nullToAbsent
          ? const Value.absent()
          : Value(textContent),
      textSelector: textSelector == null && nullToAbsent
          ? const Value.absent()
          : Value(textSelector),
      type: Value(type),
      favorite: Value(favorite),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      url: serializer.fromJson<String?>(json['url']),
      title: serializer.fromJson<String?>(json['title']),
      textContent: serializer.fromJson<String?>(json['textContent']),
      textSelector: serializer.fromJson<String?>(json['textSelector']),
      type: serializer.fromJson<String>(json['type']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'url': serializer.toJson<String?>(url),
      'title': serializer.toJson<String?>(title),
      'textContent': serializer.toJson<String?>(textContent),
      'textSelector': serializer.toJson<String?>(textSelector),
      'type': serializer.toJson<String>(type),
      'favorite': serializer.toJson<bool>(favorite),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Item copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> textContent = const Value.absent(),
    Value<String?> textSelector = const Value.absent(),
    String? type,
    bool? favorite,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Item(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    url: url.present ? url.value : this.url,
    title: title.present ? title.value : this.title,
    textContent: textContent.present ? textContent.value : this.textContent,
    textSelector: textSelector.present ? textSelector.value : this.textSelector,
    type: type ?? this.type,
    favorite: favorite ?? this.favorite,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      textSelector: data.textSelector.present
          ? data.textSelector.value
          : this.textSelector,
      type: data.type.present ? data.type.value : this.type,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('textSelector: $textSelector, ')
          ..write('type: $type, ')
          ..write('favorite: $favorite, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    url,
    title,
    textContent,
    textSelector,
    type,
    favorite,
    status,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.url == this.url &&
          other.title == this.title &&
          other.textContent == this.textContent &&
          other.textSelector == this.textSelector &&
          other.type == this.type &&
          other.favorite == this.favorite &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.deletedAt == this.deletedAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> url;
  final Value<String?> title;
  final Value<String?> textContent;
  final Value<String?> textSelector;
  final Value<String> type;
  final Value<bool> favorite;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> syncStatus;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.textContent = const Value.absent(),
    this.textSelector = const Value.absent(),
    this.type = const Value.absent(),
    this.favorite = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.textContent = const Value.absent(),
    this.textSelector = const Value.absent(),
    this.type = const Value.absent(),
    this.favorite = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? textContent,
    Expression<String>? textSelector,
    Expression<String>? type,
    Expression<bool>? favorite,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (textContent != null) 'text_content': textContent,
      if (textSelector != null) 'text_selector': textSelector,
      if (type != null) 'type': type,
      if (favorite != null) 'favorite': favorite,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? url,
    Value<String?>? title,
    Value<String?>? textContent,
    Value<String?>? textSelector,
    Value<String>? type,
    Value<bool>? favorite,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? syncStatus,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      url: url ?? this.url,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      textSelector: textSelector ?? this.textSelector,
      type: type ?? this.type,
      favorite: favorite ?? this.favorite,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (textSelector.present) {
      map['text_selector'] = Variable<String>(textSelector.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('textSelector: $textSelector, ')
          ..write('type: $type, ')
          ..write('favorite: $favorite, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalFileNameMeta = const VerificationMeta(
    'originalFileName',
  );
  @override
  late final GeneratedColumn<String> originalFileName = GeneratedColumn<String>(
    'original_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileExtensionMeta = const VerificationMeta(
    'fileExtension',
  );
  @override
  late final GeneratedColumn<String> fileExtension = GeneratedColumn<String>(
    'file_extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(file_extension <> \'\' AND file_extension = lower(file_extension) AND file_extension NOT LIKE \'.%\')',
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(byte_size BETWEEN 1 AND 104857600)',
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(length(sha256) = 64 AND sha256 NOT GLOB \'*[^0-9a-f]*\')',
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _r2ObjectKeyMeta = const VerificationMeta(
    'r2ObjectKey',
  );
  @override
  late final GeneratedColumn<String> r2ObjectKey = GeneratedColumn<String>(
    'r2_object_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NULL CHECK(width IS NULL OR width > 0)',
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NULL CHECK(height IS NULL OR height > 0)',
  );
  static const VerificationMeta _uploadStatusMeta = const VerificationMeta(
    'uploadStatus',
  );
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
    'upload_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'local\' CHECK(upload_status IN (\'local\', \'pending\', \'uploading\', \'uploaded\', \'failed\'))',
    defaultValue: const CustomExpression('\'local\''),
  );
  static const VerificationMeta _uploadAttemptsMeta = const VerificationMeta(
    'uploadAttempts',
  );
  @override
  late final GeneratedColumn<int> uploadAttempts = GeneratedColumn<int>(
    'upload_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK(upload_attempts >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _uploadLastErrorMeta = const VerificationMeta(
    'uploadLastError',
  );
  @override
  late final GeneratedColumn<String> uploadLastError = GeneratedColumn<String>(
    'upload_last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pending\' CHECK(sync_status IN (\'pending\', \'synced\', \'failed\'))',
    defaultValue: const CustomExpression('\'pending\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    userId,
    originalFileName,
    fileExtension,
    mimeType,
    byteSize,
    sha256,
    localPath,
    r2ObjectKey,
    width,
    height,
    uploadStatus,
    uploadAttempts,
    uploadLastError,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('original_file_name')) {
      context.handle(
        _originalFileNameMeta,
        originalFileName.isAcceptableOrUnknown(
          data['original_file_name']!,
          _originalFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFileNameMeta);
    }
    if (data.containsKey('file_extension')) {
      context.handle(
        _fileExtensionMeta,
        fileExtension.isAcceptableOrUnknown(
          data['file_extension']!,
          _fileExtensionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileExtensionMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('r2_object_key')) {
      context.handle(
        _r2ObjectKeyMeta,
        r2ObjectKey.isAcceptableOrUnknown(
          data['r2_object_key']!,
          _r2ObjectKeyMeta,
        ),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('upload_status')) {
      context.handle(
        _uploadStatusMeta,
        uploadStatus.isAcceptableOrUnknown(
          data['upload_status']!,
          _uploadStatusMeta,
        ),
      );
    }
    if (data.containsKey('upload_attempts')) {
      context.handle(
        _uploadAttemptsMeta,
        uploadAttempts.isAcceptableOrUnknown(
          data['upload_attempts']!,
          _uploadAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('upload_last_error')) {
      context.handle(
        _uploadLastErrorMeta,
        uploadLastError.isAcceptableOrUnknown(
          data['upload_last_error']!,
          _uploadLastErrorMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      originalFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_file_name'],
      )!,
      fileExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_extension'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      r2ObjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}r2_object_key'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      uploadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_status'],
      )!,
      uploadAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upload_attempts'],
      )!,
      uploadLastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_last_error'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String itemId;
  final String? userId;
  final String originalFileName;
  final String fileExtension;
  final String mimeType;
  final int byteSize;
  final String sha256;
  final String localPath;
  final String? r2ObjectKey;
  final int? width;
  final int? height;
  final String uploadStatus;
  final int uploadAttempts;
  final String? uploadLastError;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  const Attachment({
    required this.id,
    required this.itemId,
    this.userId,
    required this.originalFileName,
    required this.fileExtension,
    required this.mimeType,
    required this.byteSize,
    required this.sha256,
    required this.localPath,
    this.r2ObjectKey,
    this.width,
    this.height,
    required this.uploadStatus,
    required this.uploadAttempts,
    this.uploadLastError,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['original_file_name'] = Variable<String>(originalFileName);
    map['file_extension'] = Variable<String>(fileExtension);
    map['mime_type'] = Variable<String>(mimeType);
    map['byte_size'] = Variable<int>(byteSize);
    map['sha256'] = Variable<String>(sha256);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || r2ObjectKey != null) {
      map['r2_object_key'] = Variable<String>(r2ObjectKey);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['upload_status'] = Variable<String>(uploadStatus);
    map['upload_attempts'] = Variable<int>(uploadAttempts);
    if (!nullToAbsent || uploadLastError != null) {
      map['upload_last_error'] = Variable<String>(uploadLastError);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      originalFileName: Value(originalFileName),
      fileExtension: Value(fileExtension),
      mimeType: Value(mimeType),
      byteSize: Value(byteSize),
      sha256: Value(sha256),
      localPath: Value(localPath),
      r2ObjectKey: r2ObjectKey == null && nullToAbsent
          ? const Value.absent()
          : Value(r2ObjectKey),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      uploadStatus: Value(uploadStatus),
      uploadAttempts: Value(uploadAttempts),
      uploadLastError: uploadLastError == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadLastError),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      userId: serializer.fromJson<String?>(json['userId']),
      originalFileName: serializer.fromJson<String>(json['originalFileName']),
      fileExtension: serializer.fromJson<String>(json['fileExtension']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      sha256: serializer.fromJson<String>(json['sha256']),
      localPath: serializer.fromJson<String>(json['localPath']),
      r2ObjectKey: serializer.fromJson<String?>(json['r2ObjectKey']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      uploadAttempts: serializer.fromJson<int>(json['uploadAttempts']),
      uploadLastError: serializer.fromJson<String?>(json['uploadLastError']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'userId': serializer.toJson<String?>(userId),
      'originalFileName': serializer.toJson<String>(originalFileName),
      'fileExtension': serializer.toJson<String>(fileExtension),
      'mimeType': serializer.toJson<String>(mimeType),
      'byteSize': serializer.toJson<int>(byteSize),
      'sha256': serializer.toJson<String>(sha256),
      'localPath': serializer.toJson<String>(localPath),
      'r2ObjectKey': serializer.toJson<String?>(r2ObjectKey),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'uploadAttempts': serializer.toJson<int>(uploadAttempts),
      'uploadLastError': serializer.toJson<String?>(uploadLastError),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  Attachment copyWith({
    String? id,
    String? itemId,
    Value<String?> userId = const Value.absent(),
    String? originalFileName,
    String? fileExtension,
    String? mimeType,
    int? byteSize,
    String? sha256,
    String? localPath,
    Value<String?> r2ObjectKey = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    String? uploadStatus,
    int? uploadAttempts,
    Value<String?> uploadLastError = const Value.absent(),
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => Attachment(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    userId: userId.present ? userId.value : this.userId,
    originalFileName: originalFileName ?? this.originalFileName,
    fileExtension: fileExtension ?? this.fileExtension,
    mimeType: mimeType ?? this.mimeType,
    byteSize: byteSize ?? this.byteSize,
    sha256: sha256 ?? this.sha256,
    localPath: localPath ?? this.localPath,
    r2ObjectKey: r2ObjectKey.present ? r2ObjectKey.value : this.r2ObjectKey,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    uploadStatus: uploadStatus ?? this.uploadStatus,
    uploadAttempts: uploadAttempts ?? this.uploadAttempts,
    uploadLastError: uploadLastError.present
        ? uploadLastError.value
        : this.uploadLastError,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      userId: data.userId.present ? data.userId.value : this.userId,
      originalFileName: data.originalFileName.present
          ? data.originalFileName.value
          : this.originalFileName,
      fileExtension: data.fileExtension.present
          ? data.fileExtension.value
          : this.fileExtension,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      r2ObjectKey: data.r2ObjectKey.present
          ? data.r2ObjectKey.value
          : this.r2ObjectKey,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      uploadAttempts: data.uploadAttempts.present
          ? data.uploadAttempts.value
          : this.uploadAttempts,
      uploadLastError: data.uploadLastError.present
          ? data.uploadLastError.value
          : this.uploadLastError,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('sha256: $sha256, ')
          ..write('localPath: $localPath, ')
          ..write('r2ObjectKey: $r2ObjectKey, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('uploadAttempts: $uploadAttempts, ')
          ..write('uploadLastError: $uploadLastError, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    userId,
    originalFileName,
    fileExtension,
    mimeType,
    byteSize,
    sha256,
    localPath,
    r2ObjectKey,
    width,
    height,
    uploadStatus,
    uploadAttempts,
    uploadLastError,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.userId == this.userId &&
          other.originalFileName == this.originalFileName &&
          other.fileExtension == this.fileExtension &&
          other.mimeType == this.mimeType &&
          other.byteSize == this.byteSize &&
          other.sha256 == this.sha256 &&
          other.localPath == this.localPath &&
          other.r2ObjectKey == this.r2ObjectKey &&
          other.width == this.width &&
          other.height == this.height &&
          other.uploadStatus == this.uploadStatus &&
          other.uploadAttempts == this.uploadAttempts &&
          other.uploadLastError == this.uploadLastError &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String?> userId;
  final Value<String> originalFileName;
  final Value<String> fileExtension;
  final Value<String> mimeType;
  final Value<int> byteSize;
  final Value<String> sha256;
  final Value<String> localPath;
  final Value<String?> r2ObjectKey;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String> uploadStatus;
  final Value<int> uploadAttempts;
  final Value<String?> uploadLastError;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.userId = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.localPath = const Value.absent(),
    this.r2ObjectKey = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.uploadAttempts = const Value.absent(),
    this.uploadLastError = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String itemId,
    this.userId = const Value.absent(),
    required String originalFileName,
    required String fileExtension,
    required String mimeType,
    required int byteSize,
    required String sha256,
    required String localPath,
    this.r2ObjectKey = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.uploadAttempts = const Value.absent(),
    this.uploadLastError = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       originalFileName = Value(originalFileName),
       fileExtension = Value(fileExtension),
       mimeType = Value(mimeType),
       byteSize = Value(byteSize),
       sha256 = Value(sha256),
       localPath = Value(localPath),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? userId,
    Expression<String>? originalFileName,
    Expression<String>? fileExtension,
    Expression<String>? mimeType,
    Expression<int>? byteSize,
    Expression<String>? sha256,
    Expression<String>? localPath,
    Expression<String>? r2ObjectKey,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? uploadStatus,
    Expression<int>? uploadAttempts,
    Expression<String>? uploadLastError,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (userId != null) 'user_id': userId,
      if (originalFileName != null) 'original_file_name': originalFileName,
      if (fileExtension != null) 'file_extension': fileExtension,
      if (mimeType != null) 'mime_type': mimeType,
      if (byteSize != null) 'byte_size': byteSize,
      if (sha256 != null) 'sha256': sha256,
      if (localPath != null) 'local_path': localPath,
      if (r2ObjectKey != null) 'r2_object_key': r2ObjectKey,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (uploadAttempts != null) 'upload_attempts': uploadAttempts,
      if (uploadLastError != null) 'upload_last_error': uploadLastError,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String?>? userId,
    Value<String>? originalFileName,
    Value<String>? fileExtension,
    Value<String>? mimeType,
    Value<int>? byteSize,
    Value<String>? sha256,
    Value<String>? localPath,
    Value<String?>? r2ObjectKey,
    Value<int?>? width,
    Value<int?>? height,
    Value<String>? uploadStatus,
    Value<int>? uploadAttempts,
    Value<String?>? uploadLastError,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      originalFileName: originalFileName ?? this.originalFileName,
      fileExtension: fileExtension ?? this.fileExtension,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      sha256: sha256 ?? this.sha256,
      localPath: localPath ?? this.localPath,
      r2ObjectKey: r2ObjectKey ?? this.r2ObjectKey,
      width: width ?? this.width,
      height: height ?? this.height,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadAttempts: uploadAttempts ?? this.uploadAttempts,
      uploadLastError: uploadLastError ?? this.uploadLastError,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (originalFileName.present) {
      map['original_file_name'] = Variable<String>(originalFileName.value);
    }
    if (fileExtension.present) {
      map['file_extension'] = Variable<String>(fileExtension.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (r2ObjectKey.present) {
      map['r2_object_key'] = Variable<String>(r2ObjectKey.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (uploadAttempts.present) {
      map['upload_attempts'] = Variable<int>(uploadAttempts.value);
    }
    if (uploadLastError.present) {
      map['upload_last_error'] = Variable<String>(uploadLastError.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('sha256: $sha256, ')
          ..write('localPath: $localPath, ')
          ..write('r2ObjectKey: $r2ObjectKey, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('uploadAttempts: $uploadAttempts, ')
          ..write('uploadLastError: $uploadLastError, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemMetadataTable extends ItemMetadata
    with TableInfo<$ItemMetadataTable, ItemMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteNameMeta = const VerificationMeta(
    'siteName',
  );
  @override
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
    'site_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _faviconUrlMeta = const VerificationMeta(
    'faviconUrl',
  );
  @override
  late final GeneratedColumn<String> faviconUrl = GeneratedColumn<String>(
    'favicon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previewImageUrlMeta = const VerificationMeta(
    'previewImageUrl',
  );
  @override
  late final GeneratedColumn<String> previewImageUrl = GeneratedColumn<String>(
    'preview_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataVersionMeta = const VerificationMeta(
    'metadataVersion',
  );
  @override
  late final GeneratedColumn<int> metadataVersion = GeneratedColumn<int>(
    'metadata_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _enrichedAtMeta = const VerificationMeta(
    'enrichedAt',
  );
  @override
  late final GeneratedColumn<DateTime> enrichedAt = GeneratedColumn<DateTime>(
    'enriched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('link'),
  );
  static const VerificationMeta _classificationSourceMeta =
      const VerificationMeta('classificationSource');
  @override
  late final GeneratedColumn<String> classificationSource =
      GeneratedColumn<String>(
        'classification_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _classificationConfidenceMeta =
      const VerificationMeta('classificationConfidence');
  @override
  late final GeneratedColumn<double> classificationConfidence =
      GeneratedColumn<double>(
        'classification_confidence',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _structuredDataMeta = const VerificationMeta(
    'structuredData',
  );
  @override
  late final GeneratedColumn<String> structuredData = GeneratedColumn<String>(
    'structured_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    userId,
    domain,
    siteName,
    title,
    description,
    faviconUrl,
    previewImageUrl,
    status,
    attemptCount,
    lastError,
    metadataVersion,
    enrichedAt,
    contentType,
    classificationSource,
    classificationConfidence,
    structuredData,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('site_name')) {
      context.handle(
        _siteNameMeta,
        siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('favicon_url')) {
      context.handle(
        _faviconUrlMeta,
        faviconUrl.isAcceptableOrUnknown(data['favicon_url']!, _faviconUrlMeta),
      );
    }
    if (data.containsKey('preview_image_url')) {
      context.handle(
        _previewImageUrlMeta,
        previewImageUrl.isAcceptableOrUnknown(
          data['preview_image_url']!,
          _previewImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('metadata_version')) {
      context.handle(
        _metadataVersionMeta,
        metadataVersion.isAcceptableOrUnknown(
          data['metadata_version']!,
          _metadataVersionMeta,
        ),
      );
    }
    if (data.containsKey('enriched_at')) {
      context.handle(
        _enrichedAtMeta,
        enrichedAt.isAcceptableOrUnknown(data['enriched_at']!, _enrichedAtMeta),
      );
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('classification_source')) {
      context.handle(
        _classificationSourceMeta,
        classificationSource.isAcceptableOrUnknown(
          data['classification_source']!,
          _classificationSourceMeta,
        ),
      );
    }
    if (data.containsKey('classification_confidence')) {
      context.handle(
        _classificationConfidenceMeta,
        classificationConfidence.isAcceptableOrUnknown(
          data['classification_confidence']!,
          _classificationConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('structured_data')) {
      context.handle(
        _structuredDataMeta,
        structuredData.isAcceptableOrUnknown(
          data['structured_data']!,
          _structuredDataMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  ItemMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemMetadataData(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      ),
      siteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_name'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      faviconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}favicon_url'],
      ),
      previewImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_image_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      metadataVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}metadata_version'],
      )!,
      enrichedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}enriched_at'],
      ),
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      classificationSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classification_source'],
      ),
      classificationConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}classification_confidence'],
      )!,
      structuredData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}structured_data'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ItemMetadataTable createAlias(String alias) {
    return $ItemMetadataTable(attachedDatabase, alias);
  }
}

class ItemMetadataData extends DataClass
    implements Insertable<ItemMetadataData> {
  final String itemId;
  final String? userId;
  final String? domain;
  final String? siteName;
  final String? title;
  final String? description;
  final String? faviconUrl;
  final String? previewImageUrl;
  final String status;
  final int attemptCount;
  final String? lastError;
  final int metadataVersion;
  final DateTime? enrichedAt;
  final String contentType;
  final String? classificationSource;
  final double classificationConfidence;
  final String? structuredData;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ItemMetadataData({
    required this.itemId,
    this.userId,
    this.domain,
    this.siteName,
    this.title,
    this.description,
    this.faviconUrl,
    this.previewImageUrl,
    required this.status,
    required this.attemptCount,
    this.lastError,
    required this.metadataVersion,
    this.enrichedAt,
    required this.contentType,
    this.classificationSource,
    required this.classificationConfidence,
    this.structuredData,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || domain != null) {
      map['domain'] = Variable<String>(domain);
    }
    if (!nullToAbsent || siteName != null) {
      map['site_name'] = Variable<String>(siteName);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || faviconUrl != null) {
      map['favicon_url'] = Variable<String>(faviconUrl);
    }
    if (!nullToAbsent || previewImageUrl != null) {
      map['preview_image_url'] = Variable<String>(previewImageUrl);
    }
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['metadata_version'] = Variable<int>(metadataVersion);
    if (!nullToAbsent || enrichedAt != null) {
      map['enriched_at'] = Variable<DateTime>(enrichedAt);
    }
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || classificationSource != null) {
      map['classification_source'] = Variable<String>(classificationSource);
    }
    map['classification_confidence'] = Variable<double>(
      classificationConfidence,
    );
    if (!nullToAbsent || structuredData != null) {
      map['structured_data'] = Variable<String>(structuredData);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ItemMetadataCompanion toCompanion(bool nullToAbsent) {
    return ItemMetadataCompanion(
      itemId: Value(itemId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      domain: domain == null && nullToAbsent
          ? const Value.absent()
          : Value(domain),
      siteName: siteName == null && nullToAbsent
          ? const Value.absent()
          : Value(siteName),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      faviconUrl: faviconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(faviconUrl),
      previewImageUrl: previewImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(previewImageUrl),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      metadataVersion: Value(metadataVersion),
      enrichedAt: enrichedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(enrichedAt),
      contentType: Value(contentType),
      classificationSource: classificationSource == null && nullToAbsent
          ? const Value.absent()
          : Value(classificationSource),
      classificationConfidence: Value(classificationConfidence),
      structuredData: structuredData == null && nullToAbsent
          ? const Value.absent()
          : Value(structuredData),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ItemMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemMetadataData(
      itemId: serializer.fromJson<String>(json['itemId']),
      userId: serializer.fromJson<String?>(json['userId']),
      domain: serializer.fromJson<String?>(json['domain']),
      siteName: serializer.fromJson<String?>(json['siteName']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      faviconUrl: serializer.fromJson<String?>(json['faviconUrl']),
      previewImageUrl: serializer.fromJson<String?>(json['previewImageUrl']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      metadataVersion: serializer.fromJson<int>(json['metadataVersion']),
      enrichedAt: serializer.fromJson<DateTime?>(json['enrichedAt']),
      contentType: serializer.fromJson<String>(json['contentType']),
      classificationSource: serializer.fromJson<String?>(
        json['classificationSource'],
      ),
      classificationConfidence: serializer.fromJson<double>(
        json['classificationConfidence'],
      ),
      structuredData: serializer.fromJson<String?>(json['structuredData']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'userId': serializer.toJson<String?>(userId),
      'domain': serializer.toJson<String?>(domain),
      'siteName': serializer.toJson<String?>(siteName),
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
      'faviconUrl': serializer.toJson<String?>(faviconUrl),
      'previewImageUrl': serializer.toJson<String?>(previewImageUrl),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'metadataVersion': serializer.toJson<int>(metadataVersion),
      'enrichedAt': serializer.toJson<DateTime?>(enrichedAt),
      'contentType': serializer.toJson<String>(contentType),
      'classificationSource': serializer.toJson<String?>(classificationSource),
      'classificationConfidence': serializer.toJson<double>(
        classificationConfidence,
      ),
      'structuredData': serializer.toJson<String?>(structuredData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ItemMetadataData copyWith({
    String? itemId,
    Value<String?> userId = const Value.absent(),
    Value<String?> domain = const Value.absent(),
    Value<String?> siteName = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> faviconUrl = const Value.absent(),
    Value<String?> previewImageUrl = const Value.absent(),
    String? status,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    int? metadataVersion,
    Value<DateTime?> enrichedAt = const Value.absent(),
    String? contentType,
    Value<String?> classificationSource = const Value.absent(),
    double? classificationConfidence,
    Value<String?> structuredData = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ItemMetadataData(
    itemId: itemId ?? this.itemId,
    userId: userId.present ? userId.value : this.userId,
    domain: domain.present ? domain.value : this.domain,
    siteName: siteName.present ? siteName.value : this.siteName,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    faviconUrl: faviconUrl.present ? faviconUrl.value : this.faviconUrl,
    previewImageUrl: previewImageUrl.present
        ? previewImageUrl.value
        : this.previewImageUrl,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    metadataVersion: metadataVersion ?? this.metadataVersion,
    enrichedAt: enrichedAt.present ? enrichedAt.value : this.enrichedAt,
    contentType: contentType ?? this.contentType,
    classificationSource: classificationSource.present
        ? classificationSource.value
        : this.classificationSource,
    classificationConfidence:
        classificationConfidence ?? this.classificationConfidence,
    structuredData: structuredData.present
        ? structuredData.value
        : this.structuredData,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ItemMetadataData copyWithCompanion(ItemMetadataCompanion data) {
    return ItemMetadataData(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      userId: data.userId.present ? data.userId.value : this.userId,
      domain: data.domain.present ? data.domain.value : this.domain,
      siteName: data.siteName.present ? data.siteName.value : this.siteName,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      faviconUrl: data.faviconUrl.present
          ? data.faviconUrl.value
          : this.faviconUrl,
      previewImageUrl: data.previewImageUrl.present
          ? data.previewImageUrl.value
          : this.previewImageUrl,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      metadataVersion: data.metadataVersion.present
          ? data.metadataVersion.value
          : this.metadataVersion,
      enrichedAt: data.enrichedAt.present
          ? data.enrichedAt.value
          : this.enrichedAt,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      classificationSource: data.classificationSource.present
          ? data.classificationSource.value
          : this.classificationSource,
      classificationConfidence: data.classificationConfidence.present
          ? data.classificationConfidence.value
          : this.classificationConfidence,
      structuredData: data.structuredData.present
          ? data.structuredData.value
          : this.structuredData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemMetadataData(')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('domain: $domain, ')
          ..write('siteName: $siteName, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('faviconUrl: $faviconUrl, ')
          ..write('previewImageUrl: $previewImageUrl, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('metadataVersion: $metadataVersion, ')
          ..write('enrichedAt: $enrichedAt, ')
          ..write('contentType: $contentType, ')
          ..write('classificationSource: $classificationSource, ')
          ..write('classificationConfidence: $classificationConfidence, ')
          ..write('structuredData: $structuredData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    itemId,
    userId,
    domain,
    siteName,
    title,
    description,
    faviconUrl,
    previewImageUrl,
    status,
    attemptCount,
    lastError,
    metadataVersion,
    enrichedAt,
    contentType,
    classificationSource,
    classificationConfidence,
    structuredData,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemMetadataData &&
          other.itemId == this.itemId &&
          other.userId == this.userId &&
          other.domain == this.domain &&
          other.siteName == this.siteName &&
          other.title == this.title &&
          other.description == this.description &&
          other.faviconUrl == this.faviconUrl &&
          other.previewImageUrl == this.previewImageUrl &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.metadataVersion == this.metadataVersion &&
          other.enrichedAt == this.enrichedAt &&
          other.contentType == this.contentType &&
          other.classificationSource == this.classificationSource &&
          other.classificationConfidence == this.classificationConfidence &&
          other.structuredData == this.structuredData &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemMetadataCompanion extends UpdateCompanion<ItemMetadataData> {
  final Value<String> itemId;
  final Value<String?> userId;
  final Value<String?> domain;
  final Value<String?> siteName;
  final Value<String?> title;
  final Value<String?> description;
  final Value<String?> faviconUrl;
  final Value<String?> previewImageUrl;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<int> metadataVersion;
  final Value<DateTime?> enrichedAt;
  final Value<String> contentType;
  final Value<String?> classificationSource;
  final Value<double> classificationConfidence;
  final Value<String?> structuredData;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ItemMetadataCompanion({
    this.itemId = const Value.absent(),
    this.userId = const Value.absent(),
    this.domain = const Value.absent(),
    this.siteName = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.faviconUrl = const Value.absent(),
    this.previewImageUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.metadataVersion = const Value.absent(),
    this.enrichedAt = const Value.absent(),
    this.contentType = const Value.absent(),
    this.classificationSource = const Value.absent(),
    this.classificationConfidence = const Value.absent(),
    this.structuredData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemMetadataCompanion.insert({
    required String itemId,
    this.userId = const Value.absent(),
    this.domain = const Value.absent(),
    this.siteName = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.faviconUrl = const Value.absent(),
    this.previewImageUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.metadataVersion = const Value.absent(),
    this.enrichedAt = const Value.absent(),
    this.contentType = const Value.absent(),
    this.classificationSource = const Value.absent(),
    this.classificationConfidence = const Value.absent(),
    this.structuredData = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ItemMetadataData> custom({
    Expression<String>? itemId,
    Expression<String>? userId,
    Expression<String>? domain,
    Expression<String>? siteName,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? faviconUrl,
    Expression<String>? previewImageUrl,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<int>? metadataVersion,
    Expression<DateTime>? enrichedAt,
    Expression<String>? contentType,
    Expression<String>? classificationSource,
    Expression<double>? classificationConfidence,
    Expression<String>? structuredData,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (userId != null) 'user_id': userId,
      if (domain != null) 'domain': domain,
      if (siteName != null) 'site_name': siteName,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (faviconUrl != null) 'favicon_url': faviconUrl,
      if (previewImageUrl != null) 'preview_image_url': previewImageUrl,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (metadataVersion != null) 'metadata_version': metadataVersion,
      if (enrichedAt != null) 'enriched_at': enrichedAt,
      if (contentType != null) 'content_type': contentType,
      if (classificationSource != null)
        'classification_source': classificationSource,
      if (classificationConfidence != null)
        'classification_confidence': classificationConfidence,
      if (structuredData != null) 'structured_data': structuredData,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemMetadataCompanion copyWith({
    Value<String>? itemId,
    Value<String?>? userId,
    Value<String?>? domain,
    Value<String?>? siteName,
    Value<String?>? title,
    Value<String?>? description,
    Value<String?>? faviconUrl,
    Value<String?>? previewImageUrl,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<int>? metadataVersion,
    Value<DateTime?>? enrichedAt,
    Value<String>? contentType,
    Value<String?>? classificationSource,
    Value<double>? classificationConfidence,
    Value<String?>? structuredData,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ItemMetadataCompanion(
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      domain: domain ?? this.domain,
      siteName: siteName ?? this.siteName,
      title: title ?? this.title,
      description: description ?? this.description,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      metadataVersion: metadataVersion ?? this.metadataVersion,
      enrichedAt: enrichedAt ?? this.enrichedAt,
      contentType: contentType ?? this.contentType,
      classificationSource: classificationSource ?? this.classificationSource,
      classificationConfidence:
          classificationConfidence ?? this.classificationConfidence,
      structuredData: structuredData ?? this.structuredData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (faviconUrl.present) {
      map['favicon_url'] = Variable<String>(faviconUrl.value);
    }
    if (previewImageUrl.present) {
      map['preview_image_url'] = Variable<String>(previewImageUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (metadataVersion.present) {
      map['metadata_version'] = Variable<int>(metadataVersion.value);
    }
    if (enrichedAt.present) {
      map['enriched_at'] = Variable<DateTime>(enrichedAt.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (classificationSource.present) {
      map['classification_source'] = Variable<String>(
        classificationSource.value,
      );
    }
    if (classificationConfidence.present) {
      map['classification_confidence'] = Variable<double>(
        classificationConfidence.value,
      );
    }
    if (structuredData.present) {
      map['structured_data'] = Variable<String>(structuredData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemMetadataCompanion(')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('domain: $domain, ')
          ..write('siteName: $siteName, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('faviconUrl: $faviconUrl, ')
          ..write('previewImageUrl: $previewImageUrl, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('metadataVersion: $metadataVersion, ')
          ..write('enrichedAt: $enrichedAt, ')
          ..write('contentType: $contentType, ')
          ..write('classificationSource: $classificationSource, ')
          ..write('classificationConfidence: $classificationConfidence, ')
          ..write('structuredData: $structuredData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final String id;
  final String? userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final DateTime? lastSyncedAt;
  final DateTime? deletedAt;
  const Collection({
    required this.id,
    this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Collection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Collection copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Collection(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.deletedAt == this.deletedAt);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> syncStatus;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Collection> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? syncStatus,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CollectionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionItemsTable extends CollectionItems
    with TableInfo<$CollectionItemsTable, CollectionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    collectionId,
    itemId,
    userId,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, itemId};
  @override
  CollectionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionItem(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CollectionItemsTable createAlias(String alias) {
    return $CollectionItemsTable(attachedDatabase, alias);
  }
}

class CollectionItem extends DataClass implements Insertable<CollectionItem> {
  final String collectionId;
  final String itemId;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final DateTime? lastSyncedAt;
  final DateTime? deletedAt;
  const CollectionItem({
    required this.collectionId,
    required this.itemId,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CollectionItemsCompanion toCompanion(bool nullToAbsent) {
    return CollectionItemsCompanion(
      collectionId: Value(collectionId),
      itemId: Value(itemId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CollectionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionItem(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      userId: serializer.fromJson<String?>(json['userId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'itemId': serializer.toJson<String>(itemId),
      'userId': serializer.toJson<String?>(userId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CollectionItem copyWith({
    String? collectionId,
    String? itemId,
    Value<String?> userId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CollectionItem(
    collectionId: collectionId ?? this.collectionId,
    itemId: itemId ?? this.itemId,
    userId: userId.present ? userId.value : this.userId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CollectionItem copyWithCompanion(CollectionItemsCompanion data) {
    return CollectionItem(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItem(')
          ..write('collectionId: $collectionId, ')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    collectionId,
    itemId,
    userId,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionItem &&
          other.collectionId == this.collectionId &&
          other.itemId == this.itemId &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.deletedAt == this.deletedAt);
}

class CollectionItemsCompanion extends UpdateCompanion<CollectionItem> {
  final Value<String> collectionId;
  final Value<String> itemId;
  final Value<String?> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> syncStatus;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CollectionItemsCompanion({
    this.collectionId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionItemsCompanion.insert({
    required String collectionId,
    required String itemId,
    this.userId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       itemId = Value(itemId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CollectionItem> custom({
    Expression<String>? collectionId,
    Expression<String>? itemId,
    Expression<String>? userId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (itemId != null) 'item_id': itemId,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionItemsCompanion copyWith({
    Value<String>? collectionId,
    Value<String>? itemId,
    Value<String?>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? syncStatus,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CollectionItemsCompanion(
      collectionId: collectionId ?? this.collectionId,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemsCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemNotesTable extends ItemNotes
    with TableInfo<$ItemNotesTable, ItemNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    userId,
    content,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  ItemNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemNote(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ItemNotesTable createAlias(String alias) {
    return $ItemNotesTable(attachedDatabase, alias);
  }
}

class ItemNote extends DataClass implements Insertable<ItemNote> {
  final String itemId;
  final String? userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final DateTime? lastSyncedAt;
  final DateTime? deletedAt;
  const ItemNote({
    required this.itemId,
    this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ItemNotesCompanion toCompanion(bool nullToAbsent) {
    return ItemNotesCompanion(
      itemId: Value(itemId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ItemNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemNote(
      itemId: serializer.fromJson<String>(json['itemId']),
      userId: serializer.fromJson<String?>(json['userId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'userId': serializer.toJson<String?>(userId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ItemNote copyWith({
    String? itemId,
    Value<String?> userId = const Value.absent(),
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ItemNote(
    itemId: itemId ?? this.itemId,
    userId: userId.present ? userId.value : this.userId,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ItemNote copyWithCompanion(ItemNotesCompanion data) {
    return ItemNote(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      userId: data.userId.present ? data.userId.value : this.userId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemNote(')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    itemId,
    userId,
    content,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemNote &&
          other.itemId == this.itemId &&
          other.userId == this.userId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.deletedAt == this.deletedAt);
}

class ItemNotesCompanion extends UpdateCompanion<ItemNote> {
  final Value<String> itemId;
  final Value<String?> userId;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> syncStatus;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ItemNotesCompanion({
    this.itemId = const Value.absent(),
    this.userId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemNotesCompanion.insert({
    required String itemId,
    this.userId = const Value.absent(),
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ItemNote> custom({
    Expression<String>? itemId,
    Expression<String>? userId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (userId != null) 'user_id': userId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemNotesCompanion copyWith({
    Value<String>? itemId,
    Value<String?>? userId,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? syncStatus,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ItemNotesCompanion(
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemNotesCompanion(')
          ..write('itemId: $itemId, ')
          ..write('userId: $userId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String? value;
  const AppSetting({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  AppSetting copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => AppSetting(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ItemMetadataTable itemMetadata = $ItemMetadataTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $CollectionItemsTable collectionItems = $CollectionItemsTable(
    this,
  );
  late final $ItemNotesTable itemNotes = $ItemNotesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index attachmentsItemIdIdx = Index(
    'attachments_item_id_idx',
    'CREATE INDEX attachments_item_id_idx ON attachments (item_id)',
  );
  late final Index attachmentsUserIdIdx = Index(
    'attachments_user_id_idx',
    'CREATE INDEX attachments_user_id_idx ON attachments (user_id)',
  );
  late final Index attachmentsSha256Idx = Index(
    'attachments_sha256_idx',
    'CREATE INDEX attachments_sha256_idx ON attachments (sha256)',
  );
  late final Index attachmentsUploadStatusIdx = Index(
    'attachments_upload_status_idx',
    'CREATE INDEX attachments_upload_status_idx ON attachments (upload_status)',
  );
  late final Index attachmentsSyncStatusIdx = Index(
    'attachments_sync_status_idx',
    'CREATE INDEX attachments_sync_status_idx ON attachments (sync_status)',
  );
  late final Index attachmentsDeletedAtIdx = Index(
    'attachments_deleted_at_idx',
    'CREATE INDEX attachments_deleted_at_idx ON attachments (deleted_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    items,
    attachments,
    itemMetadata,
    collections,
    collectionItems,
    itemNotes,
    appSettings,
    attachmentsItemIdIdx,
    attachmentsUserIdIdx,
    attachmentsSha256Idx,
    attachmentsUploadStatusIdx,
    attachmentsSyncStatusIdx,
    attachmentsDeletedAtIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('collection_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('collection_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('item_notes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  required String id,
  Value<String?> userId,
  Value<String?> url,
  Value<String?> title,
  Value<String?> textContent,
  Value<String?> textSelector,
  Value<String> type,
  Value<bool> favorite,
  Value<String> status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> syncStatus,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<String> id,
  Value<String?> userId,
  Value<String?> url,
  Value<String?> title,
  Value<String?> textContent,
  Value<String?> textSelector,
  Value<String> type,
  Value<bool> favorite,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> syncStatus,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'items__id__attachments__item_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CollectionItemsTable, List<CollectionItem>>
  _collectionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionItems,
    aliasName: 'items__id__collection_items__item_id',
  );

  $$CollectionItemsTableProcessedTableManager get collectionItemsRefs {
    final manager = $$CollectionItemsTableTableManager(
      $_db,
      $_db.collectionItems,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemNotesTable, List<ItemNote>>
  _itemNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemNotes,
    aliasName: 'items__id__item_notes__item_id',
  );

  $$ItemNotesTableProcessedTableManager get itemNotesRefs {
    final manager = $$ItemNotesTableTableManager(
      $_db,
      $_db.itemNotes,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textSelector => $composableBuilder(
    column: $table.textSelector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> collectionItemsRefs(
    Expression<bool> Function($$CollectionItemsTableFilterComposer f) f,
  ) {
    final $$CollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemNotesRefs(
    Expression<bool> Function($$ItemNotesTableFilterComposer f) f,
  ) {
    final $$ItemNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemNotes,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemNotesTableFilterComposer(
            $db: $db,
            $table: $db.itemNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textSelector => $composableBuilder(
    column: $table.textSelector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textSelector => $composableBuilder(
    column: $table.textSelector,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> collectionItemsRefs<T extends Object>(
    Expression<T> Function($$CollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$CollectionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> itemNotesRefs<T extends Object>(
    Expression<T> Function($$ItemNotesTableAnnotationComposer a) f,
  ) {
    final $$ItemNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemNotes,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.itemNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({
            bool attachmentsRefs,
            bool collectionItemsRefs,
            bool itemNotesRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<String?> textSelector = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                userId: userId,
                url: url,
                title: title,
                textContent: textContent,
                textSelector: textSelector,
                type: type,
                favorite: favorite,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<String?> textSelector = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                userId: userId,
                url: url,
                title: title,
                textContent: textContent,
                textSelector: textSelector,
                type: type,
                favorite: favorite,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ItemsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                attachmentsRefs = false,
                collectionItemsRefs = false,
                itemNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attachmentsRefs) db.attachments,
                    if (collectionItemsRefs) db.collectionItems,
                    if (itemNotesRefs) db.itemNotes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (collectionItemsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          CollectionItem
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._collectionItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).collectionItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itemNotesRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, ItemNote>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._itemNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({
        bool attachmentsRefs,
        bool collectionItemsRefs,
        bool itemNotesRefs,
      })
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String itemId,
      Value<String?> userId,
      required String originalFileName,
      required String fileExtension,
      required String mimeType,
      required int byteSize,
      required String sha256,
      required String localPath,
      Value<String?> r2ObjectKey,
      Value<int?> width,
      Value<int?> height,
      Value<String> uploadStatus,
      Value<int> uploadAttempts,
      Value<String?> uploadLastError,
      Value<String> syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String?> userId,
      Value<String> originalFileName,
      Value<String> fileExtension,
      Value<String> mimeType,
      Value<int> byteSize,
      Value<String> sha256,
      Value<String> localPath,
      Value<String?> r2ObjectKey,
      Value<int?> width,
      Value<int?> height,
      Value<String> uploadStatus,
      Value<int> uploadAttempts,
      Value<String?> uploadLastError,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('attachments__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get r2ObjectKey => $composableBuilder(
    column: $table.r2ObjectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uploadAttempts => $composableBuilder(
    column: $table.uploadAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadLastError => $composableBuilder(
    column: $table.uploadLastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get r2ObjectKey => $composableBuilder(
    column: $table.r2ObjectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uploadAttempts => $composableBuilder(
    column: $table.uploadAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadLastError => $composableBuilder(
    column: $table.uploadLastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get r2ObjectKey => $composableBuilder(
    column: $table.r2ObjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uploadAttempts => $composableBuilder(
    column: $table.uploadAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadLastError => $composableBuilder(
    column: $table.uploadLastError,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (Attachment, $$AttachmentsTableReferences),
          Attachment,
          PrefetchHooks Function({bool itemId})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> originalFileName = const Value.absent(),
                Value<String> fileExtension = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String?> r2ObjectKey = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String> uploadStatus = const Value.absent(),
                Value<int> uploadAttempts = const Value.absent(),
                Value<String?> uploadLastError = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                itemId: itemId,
                userId: userId,
                originalFileName: originalFileName,
                fileExtension: fileExtension,
                mimeType: mimeType,
                byteSize: byteSize,
                sha256: sha256,
                localPath: localPath,
                r2ObjectKey: r2ObjectKey,
                width: width,
                height: height,
                uploadStatus: uploadStatus,
                uploadAttempts: uploadAttempts,
                uploadLastError: uploadLastError,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                Value<String?> userId = const Value.absent(),
                required String originalFileName,
                required String fileExtension,
                required String mimeType,
                required int byteSize,
                required String sha256,
                required String localPath,
                Value<String?> r2ObjectKey = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String> uploadStatus = const Value.absent(),
                Value<int> uploadAttempts = const Value.absent(),
                Value<String?> uploadLastError = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                itemId: itemId,
                userId: userId,
                originalFileName: originalFileName,
                fileExtension: fileExtension,
                mimeType: mimeType,
                byteSize: byteSize,
                sha256: sha256,
                localPath: localPath,
                r2ObjectKey: r2ObjectKey,
                width: width,
                height: height,
                uploadStatus: uploadStatus,
                uploadAttempts: uploadAttempts,
                uploadLastError: uploadLastError,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$AttachmentsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$AttachmentsTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (Attachment, $$AttachmentsTableReferences),
      Attachment,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$ItemMetadataTableCreateCompanionBuilder =
    ItemMetadataCompanion Function({
      required String itemId,
      Value<String?> userId,
      Value<String?> domain,
      Value<String?> siteName,
      Value<String?> title,
      Value<String?> description,
      Value<String?> faviconUrl,
      Value<String?> previewImageUrl,
      Value<String> status,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<int> metadataVersion,
      Value<DateTime?> enrichedAt,
      Value<String> contentType,
      Value<String?> classificationSource,
      Value<double> classificationConfidence,
      Value<String?> structuredData,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ItemMetadataTableUpdateCompanionBuilder =
    ItemMetadataCompanion Function({
      Value<String> itemId,
      Value<String?> userId,
      Value<String?> domain,
      Value<String?> siteName,
      Value<String?> title,
      Value<String?> description,
      Value<String?> faviconUrl,
      Value<String?> previewImageUrl,
      Value<String> status,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<int> metadataVersion,
      Value<DateTime?> enrichedAt,
      Value<String> contentType,
      Value<String?> classificationSource,
      Value<double> classificationConfidence,
      Value<String?> structuredData,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ItemMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $ItemMetadataTable> {
  $$ItemMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faviconUrl => $composableBuilder(
    column: $table.faviconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewImageUrl => $composableBuilder(
    column: $table.previewImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get metadataVersion => $composableBuilder(
    column: $table.metadataVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get enrichedAt => $composableBuilder(
    column: $table.enrichedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classificationSource => $composableBuilder(
    column: $table.classificationSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get classificationConfidence => $composableBuilder(
    column: $table.classificationConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get structuredData => $composableBuilder(
    column: $table.structuredData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemMetadataTable> {
  $$ItemMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faviconUrl => $composableBuilder(
    column: $table.faviconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewImageUrl => $composableBuilder(
    column: $table.previewImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get metadataVersion => $composableBuilder(
    column: $table.metadataVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get enrichedAt => $composableBuilder(
    column: $table.enrichedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classificationSource => $composableBuilder(
    column: $table.classificationSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get classificationConfidence => $composableBuilder(
    column: $table.classificationConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get structuredData => $composableBuilder(
    column: $table.structuredData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemMetadataTable> {
  $$ItemMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get siteName =>
      $composableBuilder(column: $table.siteName, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get faviconUrl => $composableBuilder(
    column: $table.faviconUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previewImageUrl => $composableBuilder(
    column: $table.previewImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get metadataVersion => $composableBuilder(
    column: $table.metadataVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get enrichedAt => $composableBuilder(
    column: $table.enrichedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get classificationSource => $composableBuilder(
    column: $table.classificationSource,
    builder: (column) => column,
  );

  GeneratedColumn<double> get classificationConfidence => $composableBuilder(
    column: $table.classificationConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get structuredData => $composableBuilder(
    column: $table.structuredData,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ItemMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemMetadataTable,
          ItemMetadataData,
          $$ItemMetadataTableFilterComposer,
          $$ItemMetadataTableOrderingComposer,
          $$ItemMetadataTableAnnotationComposer,
          $$ItemMetadataTableCreateCompanionBuilder,
          $$ItemMetadataTableUpdateCompanionBuilder,
          (
            ItemMetadataData,
            BaseReferences<_$AppDatabase, $ItemMetadataTable, ItemMetadataData>,
          ),
          ItemMetadataData,
          PrefetchHooks Function()
        > {
  $$ItemMetadataTableTableManager(_$AppDatabase db, $ItemMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<String?> siteName = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> faviconUrl = const Value.absent(),
                Value<String?> previewImageUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> metadataVersion = const Value.absent(),
                Value<DateTime?> enrichedAt = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String?> classificationSource = const Value.absent(),
                Value<double> classificationConfidence = const Value.absent(),
                Value<String?> structuredData = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemMetadataCompanion(
                itemId: itemId,
                userId: userId,
                domain: domain,
                siteName: siteName,
                title: title,
                description: description,
                faviconUrl: faviconUrl,
                previewImageUrl: previewImageUrl,
                status: status,
                attemptCount: attemptCount,
                lastError: lastError,
                metadataVersion: metadataVersion,
                enrichedAt: enrichedAt,
                contentType: contentType,
                classificationSource: classificationSource,
                classificationConfidence: classificationConfidence,
                structuredData: structuredData,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                Value<String?> userId = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<String?> siteName = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> faviconUrl = const Value.absent(),
                Value<String?> previewImageUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> metadataVersion = const Value.absent(),
                Value<DateTime?> enrichedAt = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String?> classificationSource = const Value.absent(),
                Value<double> classificationConfidence = const Value.absent(),
                Value<String?> structuredData = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ItemMetadataCompanion.insert(
                itemId: itemId,
                userId: userId,
                domain: domain,
                siteName: siteName,
                title: title,
                description: description,
                faviconUrl: faviconUrl,
                previewImageUrl: previewImageUrl,
                status: status,
                attemptCount: attemptCount,
                lastError: lastError,
                metadataVersion: metadataVersion,
                enrichedAt: enrichedAt,
                contentType: contentType,
                classificationSource: classificationSource,
                classificationConfidence: classificationConfidence,
                structuredData: structuredData,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemMetadataTable,
      ItemMetadataData,
      $$ItemMetadataTableFilterComposer,
      $$ItemMetadataTableOrderingComposer,
      $$ItemMetadataTableAnnotationComposer,
      $$ItemMetadataTableCreateCompanionBuilder,
      $$ItemMetadataTableUpdateCompanionBuilder,
      (
        ItemMetadataData,
        BaseReferences<_$AppDatabase, $ItemMetadataTable, ItemMetadataData>,
      ),
      ItemMetadataData,
      PrefetchHooks Function()
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      required String id,
      Value<String?> userId,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String> syncStatus,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> syncStatus,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$CollectionsTableReferences
    extends BaseReferences<_$AppDatabase, $CollectionsTable, Collection> {
  $$CollectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CollectionItemsTable, List<CollectionItem>>
  _collectionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionItems,
    aliasName: 'collections__id__collection_items__collection_id',
  );

  $$CollectionItemsTableProcessedTableManager get collectionItemsRefs {
    final manager = $$CollectionItemsTableTableManager(
      $_db,
      $_db.collectionItems,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectionItemsRefs(
    Expression<bool> Function($$CollectionItemsTableFilterComposer f) f,
  ) {
    final $$CollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> collectionItemsRefs<T extends Object>(
    Expression<T> Function($$CollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$CollectionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionsTable,
          Collection,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (Collection, $$CollectionsTableReferences),
          Collection,
          PrefetchHooks Function({bool collectionItemsRefs})
        > {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion(
                id: id,
                userId: userId,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (collectionItemsRefs) db.collectionItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (collectionItemsRefs)
                    await $_getPrefetchedData<
                      Collection,
                      $CollectionsTable,
                      CollectionItem
                    >(
                      currentTable: table,
                      referencedTable: $$CollectionsTableReferences
                          ._collectionItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).collectionItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.collectionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionsTable,
      Collection,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (Collection, $$CollectionsTableReferences),
      Collection,
      PrefetchHooks Function({bool collectionItemsRefs})
    >;
typedef $$CollectionItemsTableCreateCompanionBuilder =
    CollectionItemsCompanion Function({
      required String collectionId,
      required String itemId,
      Value<String?> userId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String> syncStatus,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CollectionItemsTableUpdateCompanionBuilder =
    CollectionItemsCompanion Function({
      Value<String> collectionId,
      Value<String> itemId,
      Value<String?> userId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> syncStatus,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$CollectionItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CollectionItemsTable, CollectionItem> {
  $$CollectionItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CollectionsTable _collectionIdTable(_$AppDatabase db) => db
      .collections
      .createAlias('collection_items__collection_id__collections__id');

  $$CollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$CollectionsTableTableManager(
      $_db,
      $_db.collections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('collection_items__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectionsTableFilterComposer get collectionId {
    final $$CollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableFilterComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectionsTableOrderingComposer get collectionId {
    final $$CollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$CollectionsTableAnnotationComposer get collectionId {
    final $$CollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionItemsTable,
          CollectionItem,
          $$CollectionItemsTableFilterComposer,
          $$CollectionItemsTableOrderingComposer,
          $$CollectionItemsTableAnnotationComposer,
          $$CollectionItemsTableCreateCompanionBuilder,
          $$CollectionItemsTableUpdateCompanionBuilder,
          (CollectionItem, $$CollectionItemsTableReferences),
          CollectionItem,
          PrefetchHooks Function({bool collectionId, bool itemId})
        > {
  $$CollectionItemsTableTableManager(
    _$AppDatabase db,
    $CollectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion(
                collectionId: collectionId,
                itemId: itemId,
                userId: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                required String itemId,
                Value<String?> userId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion.insert(
                collectionId: collectionId,
                itemId: itemId,
                userId: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollectionItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (collectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.collectionId,
                        referencedTable: $$CollectionItemsTableReferences
                            ._collectionIdTable(db),
                        referencedColumn: $$CollectionItemsTableReferences
                            ._collectionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$CollectionItemsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$CollectionItemsTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CollectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionItemsTable,
      CollectionItem,
      $$CollectionItemsTableFilterComposer,
      $$CollectionItemsTableOrderingComposer,
      $$CollectionItemsTableAnnotationComposer,
      $$CollectionItemsTableCreateCompanionBuilder,
      $$CollectionItemsTableUpdateCompanionBuilder,
      (CollectionItem, $$CollectionItemsTableReferences),
      CollectionItem,
      PrefetchHooks Function({bool collectionId, bool itemId})
    >;
typedef $$ItemNotesTableCreateCompanionBuilder = ItemNotesCompanion Function({
  required String itemId,
  Value<String?> userId,
  required String content,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> syncStatus,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ItemNotesTableUpdateCompanionBuilder = ItemNotesCompanion Function({
  Value<String> itemId,
  Value<String?> userId,
  Value<String> content,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> syncStatus,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ItemNotesTableReferences
    extends BaseReferences<_$AppDatabase, $ItemNotesTable, ItemNote> {
  $$ItemNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('item_notes__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemNotesTableFilterComposer
    extends Composer<_$AppDatabase, $ItemNotesTable> {
  $$ItemNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemNotesTable> {
  $$ItemNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemNotesTable> {
  $$ItemNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemNotesTable,
          ItemNote,
          $$ItemNotesTableFilterComposer,
          $$ItemNotesTableOrderingComposer,
          $$ItemNotesTableAnnotationComposer,
          $$ItemNotesTableCreateCompanionBuilder,
          $$ItemNotesTableUpdateCompanionBuilder,
          (ItemNote, $$ItemNotesTableReferences),
          ItemNote,
          PrefetchHooks Function({bool itemId})
        > {
  $$ItemNotesTableTableManager(_$AppDatabase db, $ItemNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemNotesCompanion(
                itemId: itemId,
                userId: userId,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                Value<String?> userId = const Value.absent(),
                required String content,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemNotesCompanion.insert(
                itemId: itemId,
                userId: userId,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ItemNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ItemNotesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ItemNotesTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItemNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemNotesTable,
      ItemNote,
      $$ItemNotesTableFilterComposer,
      $$ItemNotesTableOrderingComposer,
      $$ItemNotesTableAnnotationComposer,
      $$ItemNotesTableCreateCompanionBuilder,
      $$ItemNotesTableUpdateCompanionBuilder,
      (ItemNote, $$ItemNotesTableReferences),
      ItemNote,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$ItemMetadataTableTableManager get itemMetadata =>
      $$ItemMetadataTableTableManager(_db, _db.itemMetadata);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$CollectionItemsTableTableManager get collectionItems =>
      $$CollectionItemsTableTableManager(_db, _db.collectionItems);
  $$ItemNotesTableTableManager get itemNotes =>
      $$ItemNotesTableTableManager(_db, _db.itemNotes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
