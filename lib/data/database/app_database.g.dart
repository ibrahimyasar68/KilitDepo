// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EntriesTable extends Entries with TableInfo<$EntriesTable, EntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _passwordEncMeta = const VerificationMeta(
    'passwordEnc',
  );
  @override
  late final GeneratedColumn<String> passwordEnc = GeneratedColumn<String>(
    'password_enc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _notesEncMeta = const VerificationMeta(
    'notesEnc',
  );
  @override
  late final GeneratedColumn<String> notesEnc = GeneratedColumn<String>(
    'notes_enc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<String> colorKey = GeneratedColumn<String>(
    'color_key',
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
    id,
    uuid,
    title,
    username,
    passwordEnc,
    url,
    notesEnc,
    category,
    isFavorite,
    iconKey,
    colorKey,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('password_enc')) {
      context.handle(
        _passwordEncMeta,
        passwordEnc.isAcceptableOrUnknown(
          data['password_enc']!,
          _passwordEncMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordEncMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('notes_enc')) {
      context.handle(
        _notesEncMeta,
        notesEnc.isAcceptableOrUnknown(data['notes_enc']!, _notesEncMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      passwordEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_enc'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      notesEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes_enc'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_key'],
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
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class EntryRow extends DataClass implements Insertable<EntryRow> {
  final int id;
  final String uuid;
  final String title;
  final String username;
  final String passwordEnc;
  final String? url;
  final String? notesEnc;
  final String category;
  final bool isFavorite;

  /// Rozet simgesi / rengi (şema 2). Gizli değil; null = varsayılan.
  final String? iconKey;
  final String? colorKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EntryRow({
    required this.id,
    required this.uuid,
    required this.title,
    required this.username,
    required this.passwordEnc,
    this.url,
    this.notesEnc,
    required this.category,
    required this.isFavorite,
    this.iconKey,
    this.colorKey,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['title'] = Variable<String>(title);
    map['username'] = Variable<String>(username);
    map['password_enc'] = Variable<String>(passwordEnc);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || notesEnc != null) {
      map['notes_enc'] = Variable<String>(notesEnc);
    }
    map['category'] = Variable<String>(category);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    if (!nullToAbsent || colorKey != null) {
      map['color_key'] = Variable<String>(colorKey);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      title: Value(title),
      username: Value(username),
      passwordEnc: Value(passwordEnc),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      notesEnc: notesEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(notesEnc),
      category: Value(category),
      isFavorite: Value(isFavorite),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      colorKey: colorKey == null && nullToAbsent
          ? const Value.absent()
          : Value(colorKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      username: serializer.fromJson<String>(json['username']),
      passwordEnc: serializer.fromJson<String>(json['passwordEnc']),
      url: serializer.fromJson<String?>(json['url']),
      notesEnc: serializer.fromJson<String?>(json['notesEnc']),
      category: serializer.fromJson<String>(json['category']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      colorKey: serializer.fromJson<String?>(json['colorKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'title': serializer.toJson<String>(title),
      'username': serializer.toJson<String>(username),
      'passwordEnc': serializer.toJson<String>(passwordEnc),
      'url': serializer.toJson<String?>(url),
      'notesEnc': serializer.toJson<String?>(notesEnc),
      'category': serializer.toJson<String>(category),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'iconKey': serializer.toJson<String?>(iconKey),
      'colorKey': serializer.toJson<String?>(colorKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EntryRow copyWith({
    int? id,
    String? uuid,
    String? title,
    String? username,
    String? passwordEnc,
    Value<String?> url = const Value.absent(),
    Value<String?> notesEnc = const Value.absent(),
    String? category,
    bool? isFavorite,
    Value<String?> iconKey = const Value.absent(),
    Value<String?> colorKey = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EntryRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    username: username ?? this.username,
    passwordEnc: passwordEnc ?? this.passwordEnc,
    url: url.present ? url.value : this.url,
    notesEnc: notesEnc.present ? notesEnc.value : this.notesEnc,
    category: category ?? this.category,
    isFavorite: isFavorite ?? this.isFavorite,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    colorKey: colorKey.present ? colorKey.value : this.colorKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EntryRow copyWithCompanion(EntriesCompanion data) {
    return EntryRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      username: data.username.present ? data.username.value : this.username,
      passwordEnc: data.passwordEnc.present
          ? data.passwordEnc.value
          : this.passwordEnc,
      url: data.url.present ? data.url.value : this.url,
      notesEnc: data.notesEnc.present ? data.notesEnc.value : this.notesEnc,
      category: data.category.present ? data.category.value : this.category,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('username: $username, ')
          ..write('passwordEnc: $passwordEnc, ')
          ..write('url: $url, ')
          ..write('notesEnc: $notesEnc, ')
          ..write('category: $category, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    title,
    username,
    passwordEnc,
    url,
    notesEnc,
    category,
    isFavorite,
    iconKey,
    colorKey,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.username == this.username &&
          other.passwordEnc == this.passwordEnc &&
          other.url == this.url &&
          other.notesEnc == this.notesEnc &&
          other.category == this.category &&
          other.isFavorite == this.isFavorite &&
          other.iconKey == this.iconKey &&
          other.colorKey == this.colorKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EntriesCompanion extends UpdateCompanion<EntryRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> title;
  final Value<String> username;
  final Value<String> passwordEnc;
  final Value<String?> url;
  final Value<String?> notesEnc;
  final Value<String> category;
  final Value<bool> isFavorite;
  final Value<String?> iconKey;
  final Value<String?> colorKey;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordEnc = const Value.absent(),
    this.url = const Value.absent(),
    this.notesEnc = const Value.absent(),
    this.category = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String title,
    this.username = const Value.absent(),
    required String passwordEnc,
    this.url = const Value.absent(),
    this.notesEnc = const Value.absent(),
    required String category,
    this.isFavorite = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorKey = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : uuid = Value(uuid),
       title = Value(title),
       passwordEnc = Value(passwordEnc),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EntryRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? title,
    Expression<String>? username,
    Expression<String>? passwordEnc,
    Expression<String>? url,
    Expression<String>? notesEnc,
    Expression<String>? category,
    Expression<bool>? isFavorite,
    Expression<String>? iconKey,
    Expression<String>? colorKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (username != null) 'username': username,
      if (passwordEnc != null) 'password_enc': passwordEnc,
      if (url != null) 'url': url,
      if (notesEnc != null) 'notes_enc': notesEnc,
      if (category != null) 'category': category,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorKey != null) 'color_key': colorKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? title,
    Value<String>? username,
    Value<String>? passwordEnc,
    Value<String?>? url,
    Value<String?>? notesEnc,
    Value<String>? category,
    Value<bool>? isFavorite,
    Value<String?>? iconKey,
    Value<String?>? colorKey,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      username: username ?? this.username,
      passwordEnc: passwordEnc ?? this.passwordEnc,
      url: url ?? this.url,
      notesEnc: notesEnc ?? this.notesEnc,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      iconKey: iconKey ?? this.iconKey,
      colorKey: colorKey ?? this.colorKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordEnc.present) {
      map['password_enc'] = Variable<String>(passwordEnc.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (notesEnc.present) {
      map['notes_enc'] = Variable<String>(notesEnc.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<String>(colorKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('username: $username, ')
          ..write('passwordEnc: $passwordEnc, ')
          ..write('url: $url, ')
          ..write('notesEnc: $notesEnc, ')
          ..write('category: $category, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PasswordHistoryTable extends PasswordHistory
    with TableInfo<$PasswordHistoryTable, HistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PasswordHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _oldPasswordEncMeta = const VerificationMeta(
    'oldPasswordEnc',
  );
  @override
  late final GeneratedColumn<String> oldPasswordEnc = GeneratedColumn<String>(
    'old_password_enc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    oldPasswordEnc,
    changedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'password_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('old_password_enc')) {
      context.handle(
        _oldPasswordEncMeta,
        oldPasswordEnc.isAcceptableOrUnknown(
          data['old_password_enc']!,
          _oldPasswordEncMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_oldPasswordEncMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      oldPasswordEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_password_enc'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
    );
  }

  @override
  $PasswordHistoryTable createAlias(String alias) {
    return $PasswordHistoryTable(attachedDatabase, alias);
  }
}

class HistoryRow extends DataClass implements Insertable<HistoryRow> {
  final int id;
  final int entryId;
  final String oldPasswordEnc;
  final DateTime changedAt;
  const HistoryRow({
    required this.id,
    required this.entryId,
    required this.oldPasswordEnc,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['old_password_enc'] = Variable<String>(oldPasswordEnc);
    map['changed_at'] = Variable<DateTime>(changedAt);
    return map;
  }

  PasswordHistoryCompanion toCompanion(bool nullToAbsent) {
    return PasswordHistoryCompanion(
      id: Value(id),
      entryId: Value(entryId),
      oldPasswordEnc: Value(oldPasswordEnc),
      changedAt: Value(changedAt),
    );
  }

  factory HistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryRow(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      oldPasswordEnc: serializer.fromJson<String>(json['oldPasswordEnc']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'oldPasswordEnc': serializer.toJson<String>(oldPasswordEnc),
      'changedAt': serializer.toJson<DateTime>(changedAt),
    };
  }

  HistoryRow copyWith({
    int? id,
    int? entryId,
    String? oldPasswordEnc,
    DateTime? changedAt,
  }) => HistoryRow(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    oldPasswordEnc: oldPasswordEnc ?? this.oldPasswordEnc,
    changedAt: changedAt ?? this.changedAt,
  );
  HistoryRow copyWithCompanion(PasswordHistoryCompanion data) {
    return HistoryRow(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      oldPasswordEnc: data.oldPasswordEnc.present
          ? data.oldPasswordEnc.value
          : this.oldPasswordEnc,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryRow(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('oldPasswordEnc: $oldPasswordEnc, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, oldPasswordEnc, changedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryRow &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.oldPasswordEnc == this.oldPasswordEnc &&
          other.changedAt == this.changedAt);
}

class PasswordHistoryCompanion extends UpdateCompanion<HistoryRow> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<String> oldPasswordEnc;
  final Value<DateTime> changedAt;
  const PasswordHistoryCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.oldPasswordEnc = const Value.absent(),
    this.changedAt = const Value.absent(),
  });
  PasswordHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required String oldPasswordEnc,
    required DateTime changedAt,
  }) : entryId = Value(entryId),
       oldPasswordEnc = Value(oldPasswordEnc),
       changedAt = Value(changedAt);
  static Insertable<HistoryRow> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<String>? oldPasswordEnc,
    Expression<DateTime>? changedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (oldPasswordEnc != null) 'old_password_enc': oldPasswordEnc,
      if (changedAt != null) 'changed_at': changedAt,
    });
  }

  PasswordHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<String>? oldPasswordEnc,
    Value<DateTime>? changedAt,
  }) {
    return PasswordHistoryCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      oldPasswordEnc: oldPasswordEnc ?? this.oldPasswordEnc,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (oldPasswordEnc.present) {
      map['old_password_enc'] = Variable<String>(oldPasswordEnc.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PasswordHistoryCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('oldPasswordEnc: $oldPasswordEnc, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $PasswordHistoryTable passwordHistory = $PasswordHistoryTable(
    this,
  );
  late final Index passwordHistoryEntryIdx = Index(
    'password_history_entry_idx',
    'CREATE INDEX password_history_entry_idx ON password_history (entry_id)',
  );
  late final EntriesDao entriesDao = EntriesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entries,
    passwordHistory,
    passwordHistoryEntryIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('password_history', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      required String uuid,
      required String title,
      Value<String> username,
      required String passwordEnc,
      Value<String?> url,
      Value<String?> notesEnc,
      required String category,
      Value<bool> isFavorite,
      Value<String?> iconKey,
      Value<String?> colorKey,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> title,
      Value<String> username,
      Value<String> passwordEnc,
      Value<String?> url,
      Value<String?> notesEnc,
      Value<String> category,
      Value<bool> isFavorite,
      Value<String?> iconKey,
      Value<String?> colorKey,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, EntryRow> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PasswordHistoryTable, List<HistoryRow>>
  _passwordHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.passwordHistory,
    aliasName: 'entries__id__password_history__entry_id',
  );

  $$PasswordHistoryTableProcessedTableManager get passwordHistoryRefs {
    final manager = $$PasswordHistoryTableTableManager(
      $_db,
      $_db.passwordHistory,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _passwordHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordEnc => $composableBuilder(
    column: $table.passwordEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notesEnc => $composableBuilder(
    column: $table.notesEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
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

  Expression<bool> passwordHistoryRefs(
    Expression<bool> Function($$PasswordHistoryTableFilterComposer f) f,
  ) {
    final $$PasswordHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passwordHistory,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PasswordHistoryTableFilterComposer(
            $db: $db,
            $table: $db.passwordHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordEnc => $composableBuilder(
    column: $table.passwordEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notesEnc => $composableBuilder(
    column: $table.notesEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
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

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordEnc => $composableBuilder(
    column: $table.passwordEnc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get notesEnc =>
      $composableBuilder(column: $table.notesEnc, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> passwordHistoryRefs<T extends Object>(
    Expression<T> Function($$PasswordHistoryTableAnnotationComposer a) f,
  ) {
    final $$PasswordHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passwordHistory,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PasswordHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.passwordHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          EntryRow,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (EntryRow, $$EntriesTableReferences),
          EntryRow,
          PrefetchHooks Function({bool passwordHistoryRefs})
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> passwordEnc = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> notesEnc = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<String?> colorKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                uuid: uuid,
                title: title,
                username: username,
                passwordEnc: passwordEnc,
                url: url,
                notesEnc: notesEnc,
                category: category,
                isFavorite: isFavorite,
                iconKey: iconKey,
                colorKey: colorKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String title,
                Value<String> username = const Value.absent(),
                required String passwordEnc,
                Value<String?> url = const Value.absent(),
                Value<String?> notesEnc = const Value.absent(),
                required String category,
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<String?> colorKey = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => EntriesCompanion.insert(
                id: id,
                uuid: uuid,
                title: title,
                username: username,
                passwordEnc: passwordEnc,
                url: url,
                notesEnc: notesEnc,
                category: category,
                isFavorite: isFavorite,
                iconKey: iconKey,
                colorKey: colorKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, EntryRow>(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({passwordHistoryRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (passwordHistoryRefs) db.passwordHistory,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (passwordHistoryRefs)
                    await $_getPrefetchedDataByColumns<
                      EntryRow,
                      $EntriesTable,
                      HistoryRow,
                      $PasswordHistoryTable
                    >(
                      currentTable: table,
                      referencedTable: $$EntriesTableReferences
                          ._passwordHistoryRefsTable(db),
                      managerFromTypedResult: (p0) => $$EntriesTableReferences(
                        db,
                        table,
                        p0,
                      ).passwordHistoryRefs,
                      currentColumn: 'id',
                      referencedColumn: 'entry_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      EntryRow,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (EntryRow, $$EntriesTableReferences),
      EntryRow,
      PrefetchHooks Function({bool passwordHistoryRefs})
    >;
typedef $$PasswordHistoryTableCreateCompanionBuilder =
    PasswordHistoryCompanion Function({
      Value<int> id,
      required int entryId,
      required String oldPasswordEnc,
      required DateTime changedAt,
    });
typedef $$PasswordHistoryTableUpdateCompanionBuilder =
    PasswordHistoryCompanion Function({
      Value<int> id,
      Value<int> entryId,
      Value<String> oldPasswordEnc,
      Value<DateTime> changedAt,
    });

final class $$PasswordHistoryTableReferences
    extends BaseReferences<_$AppDatabase, $PasswordHistoryTable, HistoryRow> {
  $$PasswordHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntriesTable _entryIdTable(_$AppDatabase db) =>
      db.entries.createAlias('password_history__entry_id__entries__id');

  $$EntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PasswordHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PasswordHistoryTable> {
  $$PasswordHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldPasswordEnc => $composableBuilder(
    column: $table.oldPasswordEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PasswordHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PasswordHistoryTable> {
  $$PasswordHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldPasswordEnc => $composableBuilder(
    column: $table.oldPasswordEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PasswordHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PasswordHistoryTable> {
  $$PasswordHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get oldPasswordEnc => $composableBuilder(
    column: $table.oldPasswordEnc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PasswordHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PasswordHistoryTable,
          HistoryRow,
          $$PasswordHistoryTableFilterComposer,
          $$PasswordHistoryTableOrderingComposer,
          $$PasswordHistoryTableAnnotationComposer,
          $$PasswordHistoryTableCreateCompanionBuilder,
          $$PasswordHistoryTableUpdateCompanionBuilder,
          (HistoryRow, $$PasswordHistoryTableReferences),
          HistoryRow,
          PrefetchHooks Function({bool entryId})
        > {
  $$PasswordHistoryTableTableManager(
    _$AppDatabase db,
    $PasswordHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PasswordHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PasswordHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PasswordHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<String> oldPasswordEnc = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
              }) => PasswordHistoryCompanion(
                id: id,
                entryId: entryId,
                oldPasswordEnc: oldPasswordEnc,
                changedAt: changedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required String oldPasswordEnc,
                required DateTime changedAt,
              }) => PasswordHistoryCompanion.insert(
                id: id,
                entryId: entryId,
                oldPasswordEnc: oldPasswordEnc,
                changedAt: changedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PasswordHistoryTable, HistoryRow>(table),
                  $$PasswordHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
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
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable:
                                    $$PasswordHistoryTableReferences
                                        ._entryIdTable(db),
                                referencedColumn:
                                    $$PasswordHistoryTableReferences
                                        ._entryIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$PasswordHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PasswordHistoryTable,
      HistoryRow,
      $$PasswordHistoryTableFilterComposer,
      $$PasswordHistoryTableOrderingComposer,
      $$PasswordHistoryTableAnnotationComposer,
      $$PasswordHistoryTableCreateCompanionBuilder,
      $$PasswordHistoryTableUpdateCompanionBuilder,
      (HistoryRow, $$PasswordHistoryTableReferences),
      HistoryRow,
      PrefetchHooks Function({bool entryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$PasswordHistoryTableTableManager get passwordHistory =>
      $$PasswordHistoryTableTableManager(_db, _db.passwordHistory);
}
