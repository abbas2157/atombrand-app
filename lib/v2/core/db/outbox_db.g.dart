// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_db.dart';

// ignore_for_file: type=lint
class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  @override
  late final GeneratedColumn<String> seen = GeneratedColumn<String>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _filesMeta = const VerificationMeta('files');
  @override
  late final GeneratedColumn<String> files = GeneratedColumn<String>(
    'files',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempIdMeta = const VerificationMeta('tempId');
  @override
  late final GeneratedColumn<String> tempId = GeneratedColumn<String>(
    'temp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<int> shopId = GeneratedColumn<int>(
    'shop_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OutboxEntryState, int> state =
      GeneratedColumn<int>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<OutboxEntryState>($OutboxEntriesTable.$converterstate);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triesMeta = const VerificationMeta('tries');
  @override
  late final GeneratedColumn<int> tries = GeneratedColumn<int>(
    'tries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastTriedAtMeta = const VerificationMeta(
    'lastTriedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastTriedAt = GeneratedColumn<DateTime>(
    'last_tried_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    id,
    action,
    data,
    seen,
    files,
    at,
    tempId,
    shopId,
    userId,
    state,
    reason,
    message,
    tries,
    lastTriedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('seen')) {
      context.handle(
        _seenMeta,
        seen.isAcceptableOrUnknown(data['seen']!, _seenMeta),
      );
    }
    if (data.containsKey('files')) {
      context.handle(
        _filesMeta,
        files.isAcceptableOrUnknown(data['files']!, _filesMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('temp_id')) {
      context.handle(
        _tempIdMeta,
        tempId.isAcceptableOrUnknown(data['temp_id']!, _tempIdMeta),
      );
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('tries')) {
      context.handle(
        _triesMeta,
        tries.isAcceptableOrUnknown(data['tries']!, _triesMeta),
      );
    }
    if (data.containsKey('last_tried_at')) {
      context.handle(
        _lastTriedAtMeta,
        lastTriedAt.isAcceptableOrUnknown(
          data['last_tried_at']!,
          _lastTriedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      seen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seen'],
      )!,
      files: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}files'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      tempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_id'],
      ),
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shop_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      state: $OutboxEntriesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}state'],
        )!,
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      tries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tries'],
      )!,
      lastTriedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_tried_at'],
      ),
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutboxEntryState, int, int> $converterstate =
      const EnumIndexConverter<OutboxEntryState>(OutboxEntryState.values);
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  /// The order the rows are sent in.
  final int seq;
  final String id;
  final String action;

  /// The action's fields, as JSON.
  final String data;

  /// What the seller saw, for the server's money checks (§6.3).
  final String seen;

  /// The photos the action carries, as JSON: the server's field name
  /// (`instalment_pictrue`, `id_card_front_side`, …) against a file kept
  /// in the app's own storage. The camera's file is copied there when the
  /// action is queued, so a save still has its photo days later.
  final String files;

  /// The real time of the action, not of the sending.
  final DateTime at;

  /// This phone's temporary id for the record the action makes.
  final String? tempId;

  /// The shop it was done in, for an owner of several shops.
  final int? shopId;

  /// Who made it. The server applies an action as whoever owns the token
  /// it comes with, so a payment taken by one seller must never go up
  /// under the next one to sign in on this phone. Null on rows made before
  /// this was kept; they count as the signed-in person's.
  final int? userId;
  final OutboxEntryState state;

  /// Why the server would not apply it (`seen_changed`, `changed`, …).
  final String? reason;
  final String? message;

  /// How many times it has been sent, so a row that keeps failing can be
  /// held back rather than tried in a loop.
  final int tries;
  final DateTime? lastTriedAt;
  const OutboxEntry({
    required this.seq,
    required this.id,
    required this.action,
    required this.data,
    required this.seen,
    required this.files,
    required this.at,
    this.tempId,
    this.shopId,
    this.userId,
    required this.state,
    this.reason,
    this.message,
    required this.tries,
    this.lastTriedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['id'] = Variable<String>(id);
    map['action'] = Variable<String>(action);
    map['data'] = Variable<String>(data);
    map['seen'] = Variable<String>(seen);
    map['files'] = Variable<String>(files);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || tempId != null) {
      map['temp_id'] = Variable<String>(tempId);
    }
    if (!nullToAbsent || shopId != null) {
      map['shop_id'] = Variable<int>(shopId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    {
      map['state'] = Variable<int>(
        $OutboxEntriesTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['tries'] = Variable<int>(tries);
    if (!nullToAbsent || lastTriedAt != null) {
      map['last_tried_at'] = Variable<DateTime>(lastTriedAt);
    }
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      seq: Value(seq),
      id: Value(id),
      action: Value(action),
      data: Value(data),
      seen: Value(seen),
      files: Value(files),
      at: Value(at),
      tempId: tempId == null && nullToAbsent
          ? const Value.absent()
          : Value(tempId),
      shopId: shopId == null && nullToAbsent
          ? const Value.absent()
          : Value(shopId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      state: Value(state),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      tries: Value(tries),
      lastTriedAt: lastTriedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTriedAt),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      seq: serializer.fromJson<int>(json['seq']),
      id: serializer.fromJson<String>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      data: serializer.fromJson<String>(json['data']),
      seen: serializer.fromJson<String>(json['seen']),
      files: serializer.fromJson<String>(json['files']),
      at: serializer.fromJson<DateTime>(json['at']),
      tempId: serializer.fromJson<String?>(json['tempId']),
      shopId: serializer.fromJson<int?>(json['shopId']),
      userId: serializer.fromJson<int?>(json['userId']),
      state: $OutboxEntriesTable.$converterstate.fromJson(
        serializer.fromJson<int>(json['state']),
      ),
      reason: serializer.fromJson<String?>(json['reason']),
      message: serializer.fromJson<String?>(json['message']),
      tries: serializer.fromJson<int>(json['tries']),
      lastTriedAt: serializer.fromJson<DateTime?>(json['lastTriedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'id': serializer.toJson<String>(id),
      'action': serializer.toJson<String>(action),
      'data': serializer.toJson<String>(data),
      'seen': serializer.toJson<String>(seen),
      'files': serializer.toJson<String>(files),
      'at': serializer.toJson<DateTime>(at),
      'tempId': serializer.toJson<String?>(tempId),
      'shopId': serializer.toJson<int?>(shopId),
      'userId': serializer.toJson<int?>(userId),
      'state': serializer.toJson<int>(
        $OutboxEntriesTable.$converterstate.toJson(state),
      ),
      'reason': serializer.toJson<String?>(reason),
      'message': serializer.toJson<String?>(message),
      'tries': serializer.toJson<int>(tries),
      'lastTriedAt': serializer.toJson<DateTime?>(lastTriedAt),
    };
  }

  OutboxEntry copyWith({
    int? seq,
    String? id,
    String? action,
    String? data,
    String? seen,
    String? files,
    DateTime? at,
    Value<String?> tempId = const Value.absent(),
    Value<int?> shopId = const Value.absent(),
    Value<int?> userId = const Value.absent(),
    OutboxEntryState? state,
    Value<String?> reason = const Value.absent(),
    Value<String?> message = const Value.absent(),
    int? tries,
    Value<DateTime?> lastTriedAt = const Value.absent(),
  }) => OutboxEntry(
    seq: seq ?? this.seq,
    id: id ?? this.id,
    action: action ?? this.action,
    data: data ?? this.data,
    seen: seen ?? this.seen,
    files: files ?? this.files,
    at: at ?? this.at,
    tempId: tempId.present ? tempId.value : this.tempId,
    shopId: shopId.present ? shopId.value : this.shopId,
    userId: userId.present ? userId.value : this.userId,
    state: state ?? this.state,
    reason: reason.present ? reason.value : this.reason,
    message: message.present ? message.value : this.message,
    tries: tries ?? this.tries,
    lastTriedAt: lastTriedAt.present ? lastTriedAt.value : this.lastTriedAt,
  );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      seq: data.seq.present ? data.seq.value : this.seq,
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      data: data.data.present ? data.data.value : this.data,
      seen: data.seen.present ? data.seen.value : this.seen,
      files: data.files.present ? data.files.value : this.files,
      at: data.at.present ? data.at.value : this.at,
      tempId: data.tempId.present ? data.tempId.value : this.tempId,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      userId: data.userId.present ? data.userId.value : this.userId,
      state: data.state.present ? data.state.value : this.state,
      reason: data.reason.present ? data.reason.value : this.reason,
      message: data.message.present ? data.message.value : this.message,
      tries: data.tries.present ? data.tries.value : this.tries,
      lastTriedAt: data.lastTriedAt.present
          ? data.lastTriedAt.value
          : this.lastTriedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('data: $data, ')
          ..write('seen: $seen, ')
          ..write('files: $files, ')
          ..write('at: $at, ')
          ..write('tempId: $tempId, ')
          ..write('shopId: $shopId, ')
          ..write('userId: $userId, ')
          ..write('state: $state, ')
          ..write('reason: $reason, ')
          ..write('message: $message, ')
          ..write('tries: $tries, ')
          ..write('lastTriedAt: $lastTriedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    id,
    action,
    data,
    seen,
    files,
    at,
    tempId,
    shopId,
    userId,
    state,
    reason,
    message,
    tries,
    lastTriedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.seq == this.seq &&
          other.id == this.id &&
          other.action == this.action &&
          other.data == this.data &&
          other.seen == this.seen &&
          other.files == this.files &&
          other.at == this.at &&
          other.tempId == this.tempId &&
          other.shopId == this.shopId &&
          other.userId == this.userId &&
          other.state == this.state &&
          other.reason == this.reason &&
          other.message == this.message &&
          other.tries == this.tries &&
          other.lastTriedAt == this.lastTriedAt);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<int> seq;
  final Value<String> id;
  final Value<String> action;
  final Value<String> data;
  final Value<String> seen;
  final Value<String> files;
  final Value<DateTime> at;
  final Value<String?> tempId;
  final Value<int?> shopId;
  final Value<int?> userId;
  final Value<OutboxEntryState> state;
  final Value<String?> reason;
  final Value<String?> message;
  final Value<int> tries;
  final Value<DateTime?> lastTriedAt;
  const OutboxEntriesCompanion({
    this.seq = const Value.absent(),
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.data = const Value.absent(),
    this.seen = const Value.absent(),
    this.files = const Value.absent(),
    this.at = const Value.absent(),
    this.tempId = const Value.absent(),
    this.shopId = const Value.absent(),
    this.userId = const Value.absent(),
    this.state = const Value.absent(),
    this.reason = const Value.absent(),
    this.message = const Value.absent(),
    this.tries = const Value.absent(),
    this.lastTriedAt = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    this.seq = const Value.absent(),
    required String id,
    required String action,
    required String data,
    this.seen = const Value.absent(),
    this.files = const Value.absent(),
    required DateTime at,
    this.tempId = const Value.absent(),
    this.shopId = const Value.absent(),
    this.userId = const Value.absent(),
    this.state = const Value.absent(),
    this.reason = const Value.absent(),
    this.message = const Value.absent(),
    this.tries = const Value.absent(),
    this.lastTriedAt = const Value.absent(),
  }) : id = Value(id),
       action = Value(action),
       data = Value(data),
       at = Value(at);
  static Insertable<OutboxEntry> custom({
    Expression<int>? seq,
    Expression<String>? id,
    Expression<String>? action,
    Expression<String>? data,
    Expression<String>? seen,
    Expression<String>? files,
    Expression<DateTime>? at,
    Expression<String>? tempId,
    Expression<int>? shopId,
    Expression<int>? userId,
    Expression<int>? state,
    Expression<String>? reason,
    Expression<String>? message,
    Expression<int>? tries,
    Expression<DateTime>? lastTriedAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (data != null) 'data': data,
      if (seen != null) 'seen': seen,
      if (files != null) 'files': files,
      if (at != null) 'at': at,
      if (tempId != null) 'temp_id': tempId,
      if (shopId != null) 'shop_id': shopId,
      if (userId != null) 'user_id': userId,
      if (state != null) 'state': state,
      if (reason != null) 'reason': reason,
      if (message != null) 'message': message,
      if (tries != null) 'tries': tries,
      if (lastTriedAt != null) 'last_tried_at': lastTriedAt,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<int>? seq,
    Value<String>? id,
    Value<String>? action,
    Value<String>? data,
    Value<String>? seen,
    Value<String>? files,
    Value<DateTime>? at,
    Value<String?>? tempId,
    Value<int?>? shopId,
    Value<int?>? userId,
    Value<OutboxEntryState>? state,
    Value<String?>? reason,
    Value<String?>? message,
    Value<int>? tries,
    Value<DateTime?>? lastTriedAt,
  }) {
    return OutboxEntriesCompanion(
      seq: seq ?? this.seq,
      id: id ?? this.id,
      action: action ?? this.action,
      data: data ?? this.data,
      seen: seen ?? this.seen,
      files: files ?? this.files,
      at: at ?? this.at,
      tempId: tempId ?? this.tempId,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      state: state ?? this.state,
      reason: reason ?? this.reason,
      message: message ?? this.message,
      tries: tries ?? this.tries,
      lastTriedAt: lastTriedAt ?? this.lastTriedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (seen.present) {
      map['seen'] = Variable<String>(seen.value);
    }
    if (files.present) {
      map['files'] = Variable<String>(files.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (tempId.present) {
      map['temp_id'] = Variable<String>(tempId.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<int>(shopId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(
        $OutboxEntriesTable.$converterstate.toSql(state.value),
      );
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (tries.present) {
      map['tries'] = Variable<int>(tries.value);
    }
    if (lastTriedAt.present) {
      map['last_tried_at'] = Variable<DateTime>(lastTriedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('data: $data, ')
          ..write('seen: $seen, ')
          ..write('files: $files, ')
          ..write('at: $at, ')
          ..write('tempId: $tempId, ')
          ..write('shopId: $shopId, ')
          ..write('userId: $userId, ')
          ..write('state: $state, ')
          ..write('reason: $reason, ')
          ..write('message: $message, ')
          ..write('tries: $tries, ')
          ..write('lastTriedAt: $lastTriedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<int> shopId = GeneratedColumn<int>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTableMeta = const VerificationMeta(
    'sourceTable',
  );
  @override
  late final GeneratedColumn<String> sourceTable = GeneratedColumn<String>(
    'source_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _afterMeta = const VerificationMeta('after');
  @override
  late final GeneratedColumn<int> after = GeneratedColumn<int>(
    'after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [shopId, sourceTable, after];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('source_table')) {
      context.handle(
        _sourceTableMeta,
        sourceTable.isAcceptableOrUnknown(
          data['source_table']!,
          _sourceTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceTableMeta);
    }
    if (data.containsKey('after')) {
      context.handle(
        _afterMeta,
        after.isAcceptableOrUnknown(data['after']!, _afterMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopId, sourceTable};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shop_id'],
      )!,
      sourceTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_table'],
      )!,
      after: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}after'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final int shopId;

  /// A snapshot table name (`customers`, `orders`, … or `deletions`).
  /// Not `tableName`: drift keeps that name for the SQL table's own.
  final String sourceTable;

  /// The last row id this phone has of that table.
  final int after;
  const SyncCursor({
    required this.shopId,
    required this.sourceTable,
    required this.after,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_id'] = Variable<int>(shopId);
    map['source_table'] = Variable<String>(sourceTable);
    map['after'] = Variable<int>(after);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      shopId: Value(shopId),
      sourceTable: Value(sourceTable),
      after: Value(after),
    );
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      shopId: serializer.fromJson<int>(json['shopId']),
      sourceTable: serializer.fromJson<String>(json['sourceTable']),
      after: serializer.fromJson<int>(json['after']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopId': serializer.toJson<int>(shopId),
      'sourceTable': serializer.toJson<String>(sourceTable),
      'after': serializer.toJson<int>(after),
    };
  }

  SyncCursor copyWith({int? shopId, String? sourceTable, int? after}) =>
      SyncCursor(
        shopId: shopId ?? this.shopId,
        sourceTable: sourceTable ?? this.sourceTable,
        after: after ?? this.after,
      );
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      sourceTable: data.sourceTable.present
          ? data.sourceTable.value
          : this.sourceTable,
      after: data.after.present ? data.after.value : this.after,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('shopId: $shopId, ')
          ..write('sourceTable: $sourceTable, ')
          ..write('after: $after')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shopId, sourceTable, after);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.shopId == this.shopId &&
          other.sourceTable == this.sourceTable &&
          other.after == this.after);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<int> shopId;
  final Value<String> sourceTable;
  final Value<int> after;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.shopId = const Value.absent(),
    this.sourceTable = const Value.absent(),
    this.after = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required int shopId,
    required String sourceTable,
    this.after = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : shopId = Value(shopId),
       sourceTable = Value(sourceTable);
  static Insertable<SyncCursor> custom({
    Expression<int>? shopId,
    Expression<String>? sourceTable,
    Expression<int>? after,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopId != null) 'shop_id': shopId,
      if (sourceTable != null) 'source_table': sourceTable,
      if (after != null) 'after': after,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<int>? shopId,
    Value<String>? sourceTable,
    Value<int>? after,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      shopId: shopId ?? this.shopId,
      sourceTable: sourceTable ?? this.sourceTable,
      after: after ?? this.after,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopId.present) {
      map['shop_id'] = Variable<int>(shopId.value);
    }
    if (sourceTable.present) {
      map['source_table'] = Variable<String>(sourceTable.value);
    }
    if (after.present) {
      map['after'] = Variable<int>(after.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('shopId: $shopId, ')
          ..write('sourceTable: $sourceTable, ')
          ..write('after: $after, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<int> shopId = GeneratedColumn<int>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [shopId, name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopId, name};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shop_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final int shopId;
  final String name;
  final String value;
  const SyncMetaData({
    required this.shopId,
    required this.name,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_id'] = Variable<int>(shopId);
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      shopId: Value(shopId),
      name: Value(name),
      value: Value(value),
    );
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      shopId: serializer.fromJson<int>(json['shopId']),
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopId': serializer.toJson<int>(shopId),
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaData copyWith({int? shopId, String? name, String? value}) =>
      SyncMetaData(
        shopId: shopId ?? this.shopId,
        name: name ?? this.name,
        value: value ?? this.value,
      );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shopId, name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.shopId == this.shopId &&
          other.name == this.name &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<int> shopId;
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.shopId = const Value.absent(),
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required int shopId,
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : shopId = Value(shopId),
       name = Value(name),
       value = Value(value);
  static Insertable<SyncMetaData> custom({
    Expression<int>? shopId,
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopId != null) 'shop_id': shopId,
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<int>? shopId,
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopId.present) {
      map['shop_id'] = Variable<int>(shopId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
    return (StringBuffer('SyncMetaCompanion(')
          ..write('shopId: $shopId, ')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StagedPagesTable extends StagedPages
    with TableInfo<$StagedPagesTable, StagedPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StagedPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<int> shopId = GeneratedColumn<int>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [seq, shopId, payload, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staged_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<StagedPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  StagedPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StagedPage(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shop_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $StagedPagesTable createAlias(String alias) {
    return $StagedPagesTable(attachedDatabase, alias);
  }
}

class StagedPage extends DataClass implements Insertable<StagedPage> {
  final int seq;
  final int shopId;

  /// `s1:<ephemeral public key>:<nonce>:<cipher text>:<mac>`, each base64.
  final String payload;
  final DateTime at;
  const StagedPage({
    required this.seq,
    required this.shopId,
    required this.payload,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['shop_id'] = Variable<int>(shopId);
    map['payload'] = Variable<String>(payload);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  StagedPagesCompanion toCompanion(bool nullToAbsent) {
    return StagedPagesCompanion(
      seq: Value(seq),
      shopId: Value(shopId),
      payload: Value(payload),
      at: Value(at),
    );
  }

  factory StagedPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StagedPage(
      seq: serializer.fromJson<int>(json['seq']),
      shopId: serializer.fromJson<int>(json['shopId']),
      payload: serializer.fromJson<String>(json['payload']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'shopId': serializer.toJson<int>(shopId),
      'payload': serializer.toJson<String>(payload),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  StagedPage copyWith({int? seq, int? shopId, String? payload, DateTime? at}) =>
      StagedPage(
        seq: seq ?? this.seq,
        shopId: shopId ?? this.shopId,
        payload: payload ?? this.payload,
        at: at ?? this.at,
      );
  StagedPage copyWithCompanion(StagedPagesCompanion data) {
    return StagedPage(
      seq: data.seq.present ? data.seq.value : this.seq,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      payload: data.payload.present ? data.payload.value : this.payload,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StagedPage(')
          ..write('seq: $seq, ')
          ..write('shopId: $shopId, ')
          ..write('payload: $payload, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(seq, shopId, payload, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StagedPage &&
          other.seq == this.seq &&
          other.shopId == this.shopId &&
          other.payload == this.payload &&
          other.at == this.at);
}

class StagedPagesCompanion extends UpdateCompanion<StagedPage> {
  final Value<int> seq;
  final Value<int> shopId;
  final Value<String> payload;
  final Value<DateTime> at;
  const StagedPagesCompanion({
    this.seq = const Value.absent(),
    this.shopId = const Value.absent(),
    this.payload = const Value.absent(),
    this.at = const Value.absent(),
  });
  StagedPagesCompanion.insert({
    this.seq = const Value.absent(),
    required int shopId,
    required String payload,
    required DateTime at,
  }) : shopId = Value(shopId),
       payload = Value(payload),
       at = Value(at);
  static Insertable<StagedPage> custom({
    Expression<int>? seq,
    Expression<int>? shopId,
    Expression<String>? payload,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (shopId != null) 'shop_id': shopId,
      if (payload != null) 'payload': payload,
      if (at != null) 'at': at,
    });
  }

  StagedPagesCompanion copyWith({
    Value<int>? seq,
    Value<int>? shopId,
    Value<String>? payload,
    Value<DateTime>? at,
  }) {
    return StagedPagesCompanion(
      seq: seq ?? this.seq,
      shopId: shopId ?? this.shopId,
      payload: payload ?? this.payload,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<int>(shopId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StagedPagesCompanion(')
          ..write('seq: $seq, ')
          ..write('shopId: $shopId, ')
          ..write('payload: $payload, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

abstract class _$OutboxDb extends GeneratedDatabase {
  _$OutboxDb(QueryExecutor e) : super(e);
  $OutboxDbManager get managers => $OutboxDbManager(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $StagedPagesTable stagedPages = $StagedPagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxEntries,
    syncCursors,
    syncMeta,
    stagedPages,
  ];
}

typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> seq,
      required String id,
      required String action,
      required String data,
      Value<String> seen,
      Value<String> files,
      required DateTime at,
      Value<String?> tempId,
      Value<int?> shopId,
      Value<int?> userId,
      Value<OutboxEntryState> state,
      Value<String?> reason,
      Value<String?> message,
      Value<int> tries,
      Value<DateTime?> lastTriedAt,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> seq,
      Value<String> id,
      Value<String> action,
      Value<String> data,
      Value<String> seen,
      Value<String> files,
      Value<DateTime> at,
      Value<String?> tempId,
      Value<int?> shopId,
      Value<int?> userId,
      Value<OutboxEntryState> state,
      Value<String?> reason,
      Value<String?> message,
      Value<int> tries,
      Value<DateTime?> lastTriedAt,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$OutboxDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get files => $composableBuilder(
    column: $table.files,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OutboxEntryState, OutboxEntryState, int>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tries => $composableBuilder(
    column: $table.tries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$OutboxDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get files => $composableBuilder(
    column: $table.files,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempId => $composableBuilder(
    column: $table.tempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tries => $composableBuilder(
    column: $table.tries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$OutboxDb, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get seen =>
      $composableBuilder(column: $table.seen, builder: (column) => column);

  GeneratedColumn<String> get files =>
      $composableBuilder(column: $table.files, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get tempId =>
      $composableBuilder(column: $table.tempId, builder: (column) => column);

  GeneratedColumn<int> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OutboxEntryState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get tries =>
      $composableBuilder(column: $table.tries, builder: (column) => column);

  GeneratedColumn<DateTime> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => column,
  );
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$OutboxDb,
          $OutboxEntriesTable,
          OutboxEntry,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$OutboxDb, $OutboxEntriesTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(_$OutboxDb db, $OutboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<String> seen = const Value.absent(),
                Value<String> files = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> tempId = const Value.absent(),
                Value<int?> shopId = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<OutboxEntryState> state = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> tries = const Value.absent(),
                Value<DateTime?> lastTriedAt = const Value.absent(),
              }) => OutboxEntriesCompanion(
                seq: seq,
                id: id,
                action: action,
                data: data,
                seen: seen,
                files: files,
                at: at,
                tempId: tempId,
                shopId: shopId,
                userId: userId,
                state: state,
                reason: reason,
                message: message,
                tries: tries,
                lastTriedAt: lastTriedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String id,
                required String action,
                required String data,
                Value<String> seen = const Value.absent(),
                Value<String> files = const Value.absent(),
                required DateTime at,
                Value<String?> tempId = const Value.absent(),
                Value<int?> shopId = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<OutboxEntryState> state = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> tries = const Value.absent(),
                Value<DateTime?> lastTriedAt = const Value.absent(),
              }) => OutboxEntriesCompanion.insert(
                seq: seq,
                id: id,
                action: action,
                data: data,
                seen: seen,
                files: files,
                at: at,
                tempId: tempId,
                shopId: shopId,
                userId: userId,
                state: state,
                reason: reason,
                message: message,
                tries: tries,
                lastTriedAt: lastTriedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxEntriesTable, OutboxEntry>(table),
                  BaseReferences<_$OutboxDb, $OutboxEntriesTable, OutboxEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$OutboxDb,
      $OutboxEntriesTable,
      OutboxEntry,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (
        OutboxEntry,
        BaseReferences<_$OutboxDb, $OutboxEntriesTable, OutboxEntry>,
      ),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required int shopId,
      required String sourceTable,
      Value<int> after,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<int> shopId,
      Value<String> sourceTable,
      Value<int> after,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$OutboxDb, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTable => $composableBuilder(
    column: $table.sourceTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get after => $composableBuilder(
    column: $table.after,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$OutboxDb, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTable => $composableBuilder(
    column: $table.sourceTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get after => $composableBuilder(
    column: $table.after,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$OutboxDb, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get sourceTable => $composableBuilder(
    column: $table.sourceTable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get after =>
      $composableBuilder(column: $table.after, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$OutboxDb,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$OutboxDb, $SyncCursorsTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$OutboxDb db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> shopId = const Value.absent(),
                Value<String> sourceTable = const Value.absent(),
                Value<int> after = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                shopId: shopId,
                sourceTable: sourceTable,
                after: after,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int shopId,
                required String sourceTable,
                Value<int> after = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                shopId: shopId,
                sourceTable: sourceTable,
                after: after,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursor>(table),
                  BaseReferences<_$OutboxDb, $SyncCursorsTable, SyncCursor>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$OutboxDb,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (SyncCursor, BaseReferences<_$OutboxDb, $SyncCursorsTable, SyncCursor>),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required int shopId,
  required String name,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<int> shopId,
  Value<String> name,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$OutboxDb, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$OutboxDb, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$OutboxDb, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$OutboxDb,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$OutboxDb, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$OutboxDb db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> shopId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(
                shopId: shopId,
                name: name,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int shopId,
                required String name,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                shopId: shopId,
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetaTable, SyncMetaData>(table),
                  BaseReferences<_$OutboxDb, $SyncMetaTable, SyncMetaData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$OutboxDb,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (SyncMetaData, BaseReferences<_$OutboxDb, $SyncMetaTable, SyncMetaData>),
      SyncMetaData,
      PrefetchHooks Function()
    >;
typedef $$StagedPagesTableCreateCompanionBuilder =
    StagedPagesCompanion Function({
      Value<int> seq,
      required int shopId,
      required String payload,
      required DateTime at,
    });
typedef $$StagedPagesTableUpdateCompanionBuilder =
    StagedPagesCompanion Function({
      Value<int> seq,
      Value<int> shopId,
      Value<String> payload,
      Value<DateTime> at,
    });

class $$StagedPagesTableFilterComposer
    extends Composer<_$OutboxDb, $StagedPagesTable> {
  $$StagedPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StagedPagesTableOrderingComposer
    extends Composer<_$OutboxDb, $StagedPagesTable> {
  $$StagedPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shopId => $composableBuilder(
    column: $table.shopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StagedPagesTableAnnotationComposer
    extends Composer<_$OutboxDb, $StagedPagesTable> {
  $$StagedPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get shopId =>
      $composableBuilder(column: $table.shopId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$StagedPagesTableTableManager
    extends
        RootTableManager<
          _$OutboxDb,
          $StagedPagesTable,
          StagedPage,
          $$StagedPagesTableFilterComposer,
          $$StagedPagesTableOrderingComposer,
          $$StagedPagesTableAnnotationComposer,
          $$StagedPagesTableCreateCompanionBuilder,
          $$StagedPagesTableUpdateCompanionBuilder,
          (
            StagedPage,
            BaseReferences<_$OutboxDb, $StagedPagesTable, StagedPage>,
          ),
          StagedPage,
          PrefetchHooks Function()
        > {
  $$StagedPagesTableTableManager(_$OutboxDb db, $StagedPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StagedPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StagedPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StagedPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<int> shopId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => StagedPagesCompanion(
                seq: seq,
                shopId: shopId,
                payload: payload,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required int shopId,
                required String payload,
                required DateTime at,
              }) => StagedPagesCompanion.insert(
                seq: seq,
                shopId: shopId,
                payload: payload,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StagedPagesTable, StagedPage>(table),
                  BaseReferences<_$OutboxDb, $StagedPagesTable, StagedPage>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StagedPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$OutboxDb,
      $StagedPagesTable,
      StagedPage,
      $$StagedPagesTableFilterComposer,
      $$StagedPagesTableOrderingComposer,
      $$StagedPagesTableAnnotationComposer,
      $$StagedPagesTableCreateCompanionBuilder,
      $$StagedPagesTableUpdateCompanionBuilder,
      (StagedPage, BaseReferences<_$OutboxDb, $StagedPagesTable, StagedPage>),
      StagedPage,
      PrefetchHooks Function()
    >;

class $OutboxDbManager {
  final _$OutboxDb _db;
  $OutboxDbManager(this._db);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$StagedPagesTableTableManager get stagedPages =>
      $$StagedPagesTableTableManager(_db, _db.stagedPages);
}
