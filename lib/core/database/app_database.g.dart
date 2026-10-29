// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(full_name)) > 0)',
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<String> salt = GeneratedColumn<String>(
    'salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($UsersTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fullName,
    email,
    passwordHash,
    salt,
    imagePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('salt')) {
      context.handle(
        _saltMeta,
        salt.isAcceptableOrUnknown(data['salt']!, _saltMeta),
      );
    } else if (isInserting) {
      context.missing(_saltMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      salt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salt'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      createdAt: $UsersTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const EpochMsConverter();
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String salt;
  final String? imagePath;
  final DateTime createdAt;
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.salt,
    this.imagePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['salt'] = Variable<String>(salt);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    {
      map['created_at'] = Variable<int>(
        $UsersTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      fullName: Value(fullName),
      email: Value(email),
      passwordHash: Value(passwordHash),
      salt: Value(salt),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      createdAt: Value(createdAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      salt: serializer.fromJson<String>(json['salt']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'salt': serializer.toJson<String>(salt),
      'imagePath': serializer.toJson<String?>(imagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? salt,
    Value<String?> imagePath = const Value.absent(),
    DateTime? createdAt,
  }) => User(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    createdAt: createdAt ?? this.createdAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      salt: data.salt.present ? data.salt.value : this.salt,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    email,
    passwordHash,
    salt,
    imagePath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.salt == this.salt &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> salt;
  final Value<String?> imagePath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.salt = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String fullName,
    required String email,
    required String passwordHash,
    required String salt,
    this.imagePath = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName),
       email = Value(email),
       passwordHash = Value(passwordHash),
       salt = Value(salt),
       createdAt = Value(createdAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? salt,
    Expression<String>? imagePath,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (salt != null) 'salt': salt,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String>? email,
    Value<String>? passwordHash,
    Value<String>? salt,
    Value<String?>? imagePath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (salt.present) {
      map['salt'] = Variable<String>(salt.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $UsersTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    } else if (isInserting) {
      context.missing(_valueMeta);
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
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
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
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
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
    Value<String>? value,
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

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, TaskCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    $customConstraints:
        'NOT NULL UNIQUE COLLATE NOCASE CHECK (length(trim(name)) > 0)',
  );
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
    'colour',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(colour) = 7 AND substr(colour, 1, 1) = \'#\')',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colour];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('colour')) {
      context.handle(
        _colourMeta,
        colour.isAcceptableOrUnknown(data['colour']!, _colourMeta),
      );
    } else if (isInserting) {
      context.missing(_colourMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}colour'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class TaskCategory extends DataClass implements Insertable<TaskCategory> {
  final String id;
  final String name;
  final String colour;
  const TaskCategory({
    required this.id,
    required this.name,
    required this.colour,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['colour'] = Variable<String>(colour);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colour: Value(colour),
    );
  }

  factory TaskCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colour: serializer.fromJson<String>(json['colour']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colour': serializer.toJson<String>(colour),
    };
  }

  TaskCategory copyWith({String? id, String? name, String? colour}) =>
      TaskCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        colour: colour ?? this.colour,
      );
  TaskCategory copyWithCompanion(CategoriesCompanion data) {
    return TaskCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colour: data.colour.present ? data.colour.value : this.colour,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colour: $colour')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colour);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.colour == this.colour);
}

class CategoriesCompanion extends UpdateCompanion<TaskCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> colour;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colour = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String colour,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       colour = Value(colour);
  static Insertable<TaskCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colour,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colour != null) 'colour': colour,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? colour,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colour: colour ?? this.colour,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colour: $colour, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmsTable extends Alarms with TableInfo<$AlarmsTable, Alarm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (hour BETWEEN 0 AND 23)',
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (minute BETWEEN 0 AND 59)',
  );
  static const VerificationMeta _repeatDaysMeta = const VerificationMeta(
    'repeatDays',
  );
  @override
  late final GeneratedColumn<int> repeatDays = GeneratedColumn<int>(
    'repeat_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (repeat_days BETWEEN 0 AND 127)',
    defaultValue: const CustomExpression('0'),
    clientDefault: () => 0,
  );
  static const VerificationMeta _snoozeMinutesMeta = const VerificationMeta(
    'snoozeMinutes',
  );
  @override
  late final GeneratedColumn<int> snoozeMinutes = GeneratedColumn<int>(
    'snooze_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 5 CHECK (snooze_minutes BETWEEN 1 AND 120)',
    defaultValue: const CustomExpression('5'),
    clientDefault: () => 5,
  );
  static const VerificationMeta _snoozeLimitMeta = const VerificationMeta(
    'snoozeLimit',
  );
  @override
  late final GeneratedColumn<int> snoozeLimit = GeneratedColumn<int>(
    'snooze_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (snooze_limit IS NULL OR snooze_limit BETWEEN 1 AND 20)',
  );
  static const VerificationMeta _soundRefMeta = const VerificationMeta(
    'soundRef',
  );
  @override
  late final GeneratedColumn<String> soundRef = GeneratedColumn<String>(
    'sound_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'tone_1\'',
    defaultValue: const CustomExpression('\'tone_1\''),
    clientDefault: () => 'tone_1',
  );
  static const VerificationMeta _vibrateMeta = const VerificationMeta(
    'vibrate',
  );
  @override
  late final GeneratedColumn<bool> vibrate = GeneratedColumn<bool>(
    'vibrate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (vibrate IN (0, 1))',
    defaultValue: const CustomExpression('1'),
    clientDefault: () => true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))',
    defaultValue: const CustomExpression('1'),
    clientDefault: () => true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> ringOn =
      GeneratedColumn<int>(
        'ring_on',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($AlarmsTable.$converterringOnn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AlarmsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AlarmsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    hour,
    minute,
    repeatDays,
    snoozeMinutes,
    snoozeLimit,
    soundRef,
    vibrate,
    isActive,
    ringOn,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alarm> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('repeat_days')) {
      context.handle(
        _repeatDaysMeta,
        repeatDays.isAcceptableOrUnknown(data['repeat_days']!, _repeatDaysMeta),
      );
    }
    if (data.containsKey('snooze_minutes')) {
      context.handle(
        _snoozeMinutesMeta,
        snoozeMinutes.isAcceptableOrUnknown(
          data['snooze_minutes']!,
          _snoozeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('snooze_limit')) {
      context.handle(
        _snoozeLimitMeta,
        snoozeLimit.isAcceptableOrUnknown(
          data['snooze_limit']!,
          _snoozeLimitMeta,
        ),
      );
    }
    if (data.containsKey('sound_ref')) {
      context.handle(
        _soundRefMeta,
        soundRef.isAcceptableOrUnknown(data['sound_ref']!, _soundRefMeta),
      );
    }
    if (data.containsKey('vibrate')) {
      context.handle(
        _vibrateMeta,
        vibrate.isAcceptableOrUnknown(data['vibrate']!, _vibrateMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alarm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alarm(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      repeatDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_days'],
      )!,
      snoozeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_minutes'],
      )!,
      snoozeLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_limit'],
      ),
      soundRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_ref'],
      )!,
      vibrate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vibrate'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      ringOn: $AlarmsTable.$converterringOnn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}ring_on'],
        ),
      ),
      createdAt: $AlarmsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $AlarmsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $AlarmsTable createAlias(String alias) {
    return $AlarmsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterringOn =
      const EpochMsConverter();
  static TypeConverter<DateTime?, int?> $converterringOnn =
      NullAwareTypeConverter.wrap($converterringOn);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const EpochMsConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const EpochMsConverter();
}

class Alarm extends DataClass implements Insertable<Alarm> {
  final String id;
  final String? title;
  final int hour;
  final int minute;
  final int repeatDays;
  final int snoozeMinutes;
  final int? snoozeLimit;
  final String soundRef;
  final bool vibrate;
  final bool isActive;

  /// Date of a one-off alarm tied to a specific day (for example a task's
  /// linked alarm). Null for alarms that ring at the next matching time.
  final DateTime? ringOn;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Alarm({
    required this.id,
    this.title,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    required this.snoozeMinutes,
    this.snoozeLimit,
    required this.soundRef,
    required this.vibrate,
    required this.isActive,
    this.ringOn,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['repeat_days'] = Variable<int>(repeatDays);
    map['snooze_minutes'] = Variable<int>(snoozeMinutes);
    if (!nullToAbsent || snoozeLimit != null) {
      map['snooze_limit'] = Variable<int>(snoozeLimit);
    }
    map['sound_ref'] = Variable<String>(soundRef);
    map['vibrate'] = Variable<bool>(vibrate);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || ringOn != null) {
      map['ring_on'] = Variable<int>(
        $AlarmsTable.$converterringOnn.toSql(ringOn),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $AlarmsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $AlarmsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AlarmsCompanion toCompanion(bool nullToAbsent) {
    return AlarmsCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      hour: Value(hour),
      minute: Value(minute),
      repeatDays: Value(repeatDays),
      snoozeMinutes: Value(snoozeMinutes),
      snoozeLimit: snoozeLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeLimit),
      soundRef: Value(soundRef),
      vibrate: Value(vibrate),
      isActive: Value(isActive),
      ringOn: ringOn == null && nullToAbsent
          ? const Value.absent()
          : Value(ringOn),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Alarm.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alarm(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      repeatDays: serializer.fromJson<int>(json['repeatDays']),
      snoozeMinutes: serializer.fromJson<int>(json['snoozeMinutes']),
      snoozeLimit: serializer.fromJson<int?>(json['snoozeLimit']),
      soundRef: serializer.fromJson<String>(json['soundRef']),
      vibrate: serializer.fromJson<bool>(json['vibrate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      ringOn: serializer.fromJson<DateTime?>(json['ringOn']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'repeatDays': serializer.toJson<int>(repeatDays),
      'snoozeMinutes': serializer.toJson<int>(snoozeMinutes),
      'snoozeLimit': serializer.toJson<int?>(snoozeLimit),
      'soundRef': serializer.toJson<String>(soundRef),
      'vibrate': serializer.toJson<bool>(vibrate),
      'isActive': serializer.toJson<bool>(isActive),
      'ringOn': serializer.toJson<DateTime?>(ringOn),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Alarm copyWith({
    String? id,
    Value<String?> title = const Value.absent(),
    int? hour,
    int? minute,
    int? repeatDays,
    int? snoozeMinutes,
    Value<int?> snoozeLimit = const Value.absent(),
    String? soundRef,
    bool? vibrate,
    bool? isActive,
    Value<DateTime?> ringOn = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Alarm(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    repeatDays: repeatDays ?? this.repeatDays,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    snoozeLimit: snoozeLimit.present ? snoozeLimit.value : this.snoozeLimit,
    soundRef: soundRef ?? this.soundRef,
    vibrate: vibrate ?? this.vibrate,
    isActive: isActive ?? this.isActive,
    ringOn: ringOn.present ? ringOn.value : this.ringOn,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Alarm copyWithCompanion(AlarmsCompanion data) {
    return Alarm(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      repeatDays: data.repeatDays.present
          ? data.repeatDays.value
          : this.repeatDays,
      snoozeMinutes: data.snoozeMinutes.present
          ? data.snoozeMinutes.value
          : this.snoozeMinutes,
      snoozeLimit: data.snoozeLimit.present
          ? data.snoozeLimit.value
          : this.snoozeLimit,
      soundRef: data.soundRef.present ? data.soundRef.value : this.soundRef,
      vibrate: data.vibrate.present ? data.vibrate.value : this.vibrate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      ringOn: data.ringOn.present ? data.ringOn.value : this.ringOn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alarm(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('snoozeLimit: $snoozeLimit, ')
          ..write('soundRef: $soundRef, ')
          ..write('vibrate: $vibrate, ')
          ..write('isActive: $isActive, ')
          ..write('ringOn: $ringOn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    hour,
    minute,
    repeatDays,
    snoozeMinutes,
    snoozeLimit,
    soundRef,
    vibrate,
    isActive,
    ringOn,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alarm &&
          other.id == this.id &&
          other.title == this.title &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.repeatDays == this.repeatDays &&
          other.snoozeMinutes == this.snoozeMinutes &&
          other.snoozeLimit == this.snoozeLimit &&
          other.soundRef == this.soundRef &&
          other.vibrate == this.vibrate &&
          other.isActive == this.isActive &&
          other.ringOn == this.ringOn &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AlarmsCompanion extends UpdateCompanion<Alarm> {
  final Value<String> id;
  final Value<String?> title;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int> repeatDays;
  final Value<int> snoozeMinutes;
  final Value<int?> snoozeLimit;
  final Value<String> soundRef;
  final Value<bool> vibrate;
  final Value<bool> isActive;
  final Value<DateTime?> ringOn;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AlarmsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.repeatDays = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.snoozeLimit = const Value.absent(),
    this.soundRef = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.ringOn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    required int hour,
    required int minute,
    this.repeatDays = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.snoozeLimit = const Value.absent(),
    this.soundRef = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.ringOn = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hour = Value(hour),
       minute = Value(minute),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Alarm> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? repeatDays,
    Expression<int>? snoozeMinutes,
    Expression<int>? snoozeLimit,
    Expression<String>? soundRef,
    Expression<bool>? vibrate,
    Expression<bool>? isActive,
    Expression<int>? ringOn,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (repeatDays != null) 'repeat_days': repeatDays,
      if (snoozeMinutes != null) 'snooze_minutes': snoozeMinutes,
      if (snoozeLimit != null) 'snooze_limit': snoozeLimit,
      if (soundRef != null) 'sound_ref': soundRef,
      if (vibrate != null) 'vibrate': vibrate,
      if (isActive != null) 'is_active': isActive,
      if (ringOn != null) 'ring_on': ringOn,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmsCompanion copyWith({
    Value<String>? id,
    Value<String?>? title,
    Value<int>? hour,
    Value<int>? minute,
    Value<int>? repeatDays,
    Value<int>? snoozeMinutes,
    Value<int?>? snoozeLimit,
    Value<String>? soundRef,
    Value<bool>? vibrate,
    Value<bool>? isActive,
    Value<DateTime?>? ringOn,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AlarmsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      snoozeLimit: snoozeLimit ?? this.snoozeLimit,
      soundRef: soundRef ?? this.soundRef,
      vibrate: vibrate ?? this.vibrate,
      isActive: isActive ?? this.isActive,
      ringOn: ringOn ?? this.ringOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (repeatDays.present) {
      map['repeat_days'] = Variable<int>(repeatDays.value);
    }
    if (snoozeMinutes.present) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes.value);
    }
    if (snoozeLimit.present) {
      map['snooze_limit'] = Variable<int>(snoozeLimit.value);
    }
    if (soundRef.present) {
      map['sound_ref'] = Variable<String>(soundRef.value);
    }
    if (vibrate.present) {
      map['vibrate'] = Variable<bool>(vibrate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (ringOn.present) {
      map['ring_on'] = Variable<int>(
        $AlarmsTable.$converterringOnn.toSql(ringOn.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $AlarmsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $AlarmsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('snoozeLimit: $snoozeLimit, ')
          ..write('soundRef: $soundRef, ')
          ..write('vibrate: $vibrate, ')
          ..write('isActive: $isActive, ')
          ..write('ringOn: $ringOn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmChallengesTable extends AlarmChallenges
    with TableInfo<$AlarmChallengesTable, AlarmChallenge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmChallengesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alarmIdMeta = const VerificationMeta(
    'alarmId',
  );
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
    'alarm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE REFERENCES alarms (id) ON DELETE CASCADE',
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChallengeType, String>
  challengeType = GeneratedColumn<String>(
    'challenge_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (challenge_type IN (\'maths\', \'memory\', \'phrase\', \'shake\'))',
  ).withConverter<ChallengeType>($AlarmChallengesTable.$converterchallengeType);
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 5)',
    defaultValue: const CustomExpression('2'),
    clientDefault: () => 2,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    alarmId,
    challengeType,
    difficulty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarm_challenges';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlarmChallenge> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('alarm_id')) {
      context.handle(
        _alarmIdMeta,
        alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlarmChallenge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmChallenge(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      alarmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_id'],
      )!,
      challengeType: $AlarmChallengesTable.$converterchallengeType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}challenge_type'],
        )!,
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
    );
  }

  @override
  $AlarmChallengesTable createAlias(String alias) {
    return $AlarmChallengesTable(attachedDatabase, alias);
  }

  static TypeConverter<ChallengeType, String> $converterchallengeType =
      const ChallengeTypeConverter();
}

class AlarmChallenge extends DataClass implements Insertable<AlarmChallenge> {
  final String id;
  final String alarmId;
  final ChallengeType challengeType;
  final int difficulty;
  const AlarmChallenge({
    required this.id,
    required this.alarmId,
    required this.challengeType,
    required this.difficulty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['alarm_id'] = Variable<String>(alarmId);
    {
      map['challenge_type'] = Variable<String>(
        $AlarmChallengesTable.$converterchallengeType.toSql(challengeType),
      );
    }
    map['difficulty'] = Variable<int>(difficulty);
    return map;
  }

  AlarmChallengesCompanion toCompanion(bool nullToAbsent) {
    return AlarmChallengesCompanion(
      id: Value(id),
      alarmId: Value(alarmId),
      challengeType: Value(challengeType),
      difficulty: Value(difficulty),
    );
  }

  factory AlarmChallenge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmChallenge(
      id: serializer.fromJson<String>(json['id']),
      alarmId: serializer.fromJson<String>(json['alarmId']),
      challengeType: serializer.fromJson<ChallengeType>(json['challengeType']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'alarmId': serializer.toJson<String>(alarmId),
      'challengeType': serializer.toJson<ChallengeType>(challengeType),
      'difficulty': serializer.toJson<int>(difficulty),
    };
  }

  AlarmChallenge copyWith({
    String? id,
    String? alarmId,
    ChallengeType? challengeType,
    int? difficulty,
  }) => AlarmChallenge(
    id: id ?? this.id,
    alarmId: alarmId ?? this.alarmId,
    challengeType: challengeType ?? this.challengeType,
    difficulty: difficulty ?? this.difficulty,
  );
  AlarmChallenge copyWithCompanion(AlarmChallengesCompanion data) {
    return AlarmChallenge(
      id: data.id.present ? data.id.value : this.id,
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      challengeType: data.challengeType.present
          ? data.challengeType.value
          : this.challengeType,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmChallenge(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('challengeType: $challengeType, ')
          ..write('difficulty: $difficulty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, alarmId, challengeType, difficulty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmChallenge &&
          other.id == this.id &&
          other.alarmId == this.alarmId &&
          other.challengeType == this.challengeType &&
          other.difficulty == this.difficulty);
}

class AlarmChallengesCompanion extends UpdateCompanion<AlarmChallenge> {
  final Value<String> id;
  final Value<String> alarmId;
  final Value<ChallengeType> challengeType;
  final Value<int> difficulty;
  final Value<int> rowid;
  const AlarmChallengesCompanion({
    this.id = const Value.absent(),
    this.alarmId = const Value.absent(),
    this.challengeType = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmChallengesCompanion.insert({
    required String id,
    required String alarmId,
    required ChallengeType challengeType,
    this.difficulty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       alarmId = Value(alarmId),
       challengeType = Value(challengeType);
  static Insertable<AlarmChallenge> custom({
    Expression<String>? id,
    Expression<String>? alarmId,
    Expression<String>? challengeType,
    Expression<int>? difficulty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alarmId != null) 'alarm_id': alarmId,
      if (challengeType != null) 'challenge_type': challengeType,
      if (difficulty != null) 'difficulty': difficulty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmChallengesCompanion copyWith({
    Value<String>? id,
    Value<String>? alarmId,
    Value<ChallengeType>? challengeType,
    Value<int>? difficulty,
    Value<int>? rowid,
  }) {
    return AlarmChallengesCompanion(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      challengeType: challengeType ?? this.challengeType,
      difficulty: difficulty ?? this.difficulty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (challengeType.present) {
      map['challenge_type'] = Variable<String>(
        $AlarmChallengesTable.$converterchallengeType.toSql(
          challengeType.value,
        ),
      );
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmChallengesCompanion(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('challengeType: $challengeType, ')
          ..write('difficulty: $difficulty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'My event\' CHECK (length(trim(title)) > 0)',
    defaultValue: const CustomExpression('\'My event\''),
    clientDefault: () => 'My event',
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startAt =
      GeneratedColumn<int>(
        'start_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CalendarEventsTable.$converterstartAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> endAt =
      GeneratedColumn<int>(
        'end_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CalendarEventsTable.$converterendAt);
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (is_all_day IN (0, 1))',
    defaultValue: const CustomExpression('0'),
    clientDefault: () => false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
    'colour',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderMinutesBeforeMeta =
      const VerificationMeta('reminderMinutesBefore');
  @override
  late final GeneratedColumn<int> reminderMinutesBefore = GeneratedColumn<int>(
    'reminder_minutes_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (reminder_minutes_before IS NULL OR reminder_minutes_before >= 0)',
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta(
    'repeatRule',
  );
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAutoMeta = const VerificationMeta('isAuto');
  @override
  late final GeneratedColumn<bool> isAuto = GeneratedColumn<bool>(
    'is_auto',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (is_auto IN (0, 1))',
    defaultValue: const CustomExpression('0'),
    clientDefault: () => false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CalendarEventsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    startAt,
    endAt,
    isAllDay,
    location,
    colour,
    reminderMinutesBefore,
    repeatRule,
    isAuto,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('colour')) {
      context.handle(
        _colourMeta,
        colour.isAcceptableOrUnknown(data['colour']!, _colourMeta),
      );
    } else if (isInserting) {
      context.missing(_colourMeta);
    }
    if (data.containsKey('reminder_minutes_before')) {
      context.handle(
        _reminderMinutesBeforeMeta,
        reminderMinutesBefore.isAcceptableOrUnknown(
          data['reminder_minutes_before']!,
          _reminderMinutesBeforeMeta,
        ),
      );
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('is_auto')) {
      context.handle(
        _isAutoMeta,
        isAuto.isAcceptableOrUnknown(data['is_auto']!, _isAutoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startAt: $CalendarEventsTable.$converterstartAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}start_at'],
        )!,
      ),
      endAt: $CalendarEventsTable.$converterendAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}end_at'],
        )!,
      ),
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      colour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}colour'],
      )!,
      reminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes_before'],
      ),
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      ),
      isAuto: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_auto'],
      )!,
      createdAt: $CalendarEventsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartAt =
      const EpochMsConverter();
  static TypeConverter<DateTime, int> $converterendAt =
      const EpochMsConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const EpochMsConverter();
}

class CalendarEvent extends DataClass implements Insertable<CalendarEvent> {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final bool isAllDay;
  final String? location;
  final String colour;
  final int? reminderMinutesBefore;
  final String? repeatRule;
  final bool isAuto;
  final DateTime createdAt;
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.isAllDay,
    this.location,
    required this.colour,
    this.reminderMinutesBefore,
    this.repeatRule,
    required this.isAuto,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    {
      map['start_at'] = Variable<int>(
        $CalendarEventsTable.$converterstartAt.toSql(startAt),
      );
    }
    {
      map['end_at'] = Variable<int>(
        $CalendarEventsTable.$converterendAt.toSql(endAt),
      );
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['colour'] = Variable<String>(colour);
    if (!nullToAbsent || reminderMinutesBefore != null) {
      map['reminder_minutes_before'] = Variable<int>(reminderMinutesBefore);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    map['is_auto'] = Variable<bool>(isAuto);
    {
      map['created_at'] = Variable<int>(
        $CalendarEventsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      title: Value(title),
      startAt: Value(startAt),
      endAt: Value(endAt),
      isAllDay: Value(isAllDay),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      colour: Value(colour),
      reminderMinutesBefore: reminderMinutesBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutesBefore),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      isAuto: Value(isAuto),
      createdAt: Value(createdAt),
    );
  }

  factory CalendarEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEvent(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      endAt: serializer.fromJson<DateTime>(json['endAt']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      location: serializer.fromJson<String?>(json['location']),
      colour: serializer.fromJson<String>(json['colour']),
      reminderMinutesBefore: serializer.fromJson<int?>(
        json['reminderMinutesBefore'],
      ),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      isAuto: serializer.fromJson<bool>(json['isAuto']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'startAt': serializer.toJson<DateTime>(startAt),
      'endAt': serializer.toJson<DateTime>(endAt),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'location': serializer.toJson<String?>(location),
      'colour': serializer.toJson<String>(colour),
      'reminderMinutesBefore': serializer.toJson<int?>(reminderMinutesBefore),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'isAuto': serializer.toJson<bool>(isAuto),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool? isAllDay,
    Value<String?> location = const Value.absent(),
    String? colour,
    Value<int?> reminderMinutesBefore = const Value.absent(),
    Value<String?> repeatRule = const Value.absent(),
    bool? isAuto,
    DateTime? createdAt,
  }) => CalendarEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    isAllDay: isAllDay ?? this.isAllDay,
    location: location.present ? location.value : this.location,
    colour: colour ?? this.colour,
    reminderMinutesBefore: reminderMinutesBefore.present
        ? reminderMinutesBefore.value
        : this.reminderMinutesBefore,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    isAuto: isAuto ?? this.isAuto,
    createdAt: createdAt ?? this.createdAt,
  );
  CalendarEvent copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      location: data.location.present ? data.location.value : this.location,
      colour: data.colour.present ? data.colour.value : this.colour,
      reminderMinutesBefore: data.reminderMinutesBefore.present
          ? data.reminderMinutesBefore.value
          : this.reminderMinutesBefore,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      isAuto: data.isAuto.present ? data.isAuto.value : this.isAuto,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('location: $location, ')
          ..write('colour: $colour, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('isAuto: $isAuto, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startAt,
    endAt,
    isAllDay,
    location,
    colour,
    reminderMinutesBefore,
    repeatRule,
    isAuto,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.isAllDay == this.isAllDay &&
          other.location == this.location &&
          other.colour == this.colour &&
          other.reminderMinutesBefore == this.reminderMinutesBefore &&
          other.repeatRule == this.repeatRule &&
          other.isAuto == this.isAuto &&
          other.createdAt == this.createdAt);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEvent> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> startAt;
  final Value<DateTime> endAt;
  final Value<bool> isAllDay;
  final Value<String?> location;
  final Value<String> colour;
  final Value<int?> reminderMinutesBefore;
  final Value<String?> repeatRule;
  final Value<bool> isAuto;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.location = const Value.absent(),
    this.colour = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.isAuto = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    required DateTime startAt,
    required DateTime endAt,
    this.isAllDay = const Value.absent(),
    this.location = const Value.absent(),
    required String colour,
    this.reminderMinutesBefore = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.isAuto = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startAt = Value(startAt),
       endAt = Value(endAt),
       colour = Value(colour),
       createdAt = Value(createdAt);
  static Insertable<CalendarEvent> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? startAt,
    Expression<int>? endAt,
    Expression<bool>? isAllDay,
    Expression<String>? location,
    Expression<String>? colour,
    Expression<int>? reminderMinutesBefore,
    Expression<String>? repeatRule,
    Expression<bool>? isAuto,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (location != null) 'location': location,
      if (colour != null) 'colour': colour,
      if (reminderMinutesBefore != null)
        'reminder_minutes_before': reminderMinutesBefore,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (isAuto != null) 'is_auto': isAuto,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? startAt,
    Value<DateTime>? endAt,
    Value<bool>? isAllDay,
    Value<String?>? location,
    Value<String>? colour,
    Value<int?>? reminderMinutesBefore,
    Value<String?>? repeatRule,
    Value<bool>? isAuto,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      colour: colour ?? this.colour,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      repeatRule: repeatRule ?? this.repeatRule,
      isAuto: isAuto ?? this.isAuto,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(
        $CalendarEventsTable.$converterstartAt.toSql(startAt.value),
      );
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(
        $CalendarEventsTable.$converterendAt.toSql(endAt.value),
      );
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (reminderMinutesBefore.present) {
      map['reminder_minutes_before'] = Variable<int>(
        reminderMinutesBefore.value,
      );
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (isAuto.present) {
      map['is_auto'] = Variable<bool>(isAuto.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $CalendarEventsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('location: $location, ')
          ..write('colour: $colour, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('isAuto: $isAuto, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(title)) > 0)',
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskPriority, String>
  priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'medium\' CHECK (priority IN (\'high\', \'medium\', \'low\'))',
    defaultValue: const CustomExpression('\'medium\''),
    clientDefault: () => 'medium',
  ).withConverter<TaskPriority>($TasksTable.$converterpriority);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> dueAt =
      GeneratedColumn<int>(
        'due_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($TasksTable.$converterdueAtn);
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (is_all_day IN (0, 1))',
    defaultValue: const CustomExpression('0'),
    clientDefault: () => false,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (is_done IN (0, 1))',
    defaultValue: const CustomExpression('0'),
    clientDefault: () => false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> completedAt =
      GeneratedColumn<int>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($TasksTable.$convertercompletedAtn);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES categories (id) ON DELETE SET NULL',
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES calendar_events (id) ON DELETE SET NULL',
  );
  static const VerificationMeta _alarmIdMeta = const VerificationMeta(
    'alarmId',
  );
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
    'alarm_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES alarms (id) ON DELETE SET NULL',
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TasksTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    priority,
    dueAt,
    isAllDay,
    isDone,
    completedAt,
    categoryId,
    eventId,
    alarmId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('alarm_id')) {
      context.handle(
        _alarmIdMeta,
        alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      priority: $TasksTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        )!,
      ),
      dueAt: $TasksTable.$converterdueAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}due_at'],
        ),
      ),
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      completedAt: $TasksTable.$convertercompletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}completed_at'],
        ),
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      ),
      alarmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_id'],
      ),
      createdAt: $TasksTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static TypeConverter<TaskPriority, String> $converterpriority =
      const TaskPriorityConverter();
  static TypeConverter<DateTime, int> $converterdueAt =
      const EpochMsConverter();
  static TypeConverter<DateTime?, int?> $converterdueAtn =
      NullAwareTypeConverter.wrap($converterdueAt);
  static TypeConverter<DateTime, int> $convertercompletedAt =
      const EpochMsConverter();
  static TypeConverter<DateTime?, int?> $convertercompletedAtn =
      NullAwareTypeConverter.wrap($convertercompletedAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const EpochMsConverter();
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final TaskPriority priority;
  final DateTime? dueAt;
  final bool isAllDay;
  final bool isDone;
  final DateTime? completedAt;
  final String? categoryId;
  final String? eventId;
  final String? alarmId;
  final DateTime createdAt;
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    this.dueAt,
    required this.isAllDay,
    required this.isDone,
    this.completedAt,
    this.categoryId,
    this.eventId,
    this.alarmId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    {
      map['priority'] = Variable<String>(
        $TasksTable.$converterpriority.toSql(priority),
      );
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<int>($TasksTable.$converterdueAtn.toSql(dueAt));
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(
        $TasksTable.$convertercompletedAtn.toSql(completedAt),
      );
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || alarmId != null) {
      map['alarm_id'] = Variable<String>(alarmId);
    }
    {
      map['created_at'] = Variable<int>(
        $TasksTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      priority: Value(priority),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      isAllDay: Value(isAllDay),
      isDone: Value(isDone),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      alarmId: alarmId == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmId),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      priority: serializer.fromJson<TaskPriority>(json['priority']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      alarmId: serializer.fromJson<String?>(json['alarmId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'priority': serializer.toJson<TaskPriority>(priority),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'isDone': serializer.toJson<bool>(isDone),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'categoryId': serializer.toJson<String?>(categoryId),
      'eventId': serializer.toJson<String?>(eventId),
      'alarmId': serializer.toJson<String?>(alarmId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    Value<DateTime?> dueAt = const Value.absent(),
    bool? isAllDay,
    bool? isDone,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> eventId = const Value.absent(),
    Value<String?> alarmId = const Value.absent(),
    DateTime? createdAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    priority: priority ?? this.priority,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    isAllDay: isAllDay ?? this.isAllDay,
    isDone: isDone ?? this.isDone,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    eventId: eventId.present ? eventId.value : this.eventId,
    alarmId: alarmId.present ? alarmId.value : this.alarmId,
    createdAt: createdAt ?? this.createdAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('priority: $priority, ')
          ..write('dueAt: $dueAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isDone: $isDone, ')
          ..write('completedAt: $completedAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('eventId: $eventId, ')
          ..write('alarmId: $alarmId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    priority,
    dueAt,
    isAllDay,
    isDone,
    completedAt,
    categoryId,
    eventId,
    alarmId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.priority == this.priority &&
          other.dueAt == this.dueAt &&
          other.isAllDay == this.isAllDay &&
          other.isDone == this.isDone &&
          other.completedAt == this.completedAt &&
          other.categoryId == this.categoryId &&
          other.eventId == this.eventId &&
          other.alarmId == this.alarmId &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<TaskPriority> priority;
  final Value<DateTime?> dueAt;
  final Value<bool> isAllDay;
  final Value<bool> isDone;
  final Value<DateTime?> completedAt;
  final Value<String?> categoryId;
  final Value<String?> eventId;
  final Value<String?> alarmId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isDone = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.alarmId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.priority = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isDone = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.alarmId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? priority,
    Expression<int>? dueAt,
    Expression<bool>? isAllDay,
    Expression<bool>? isDone,
    Expression<int>? completedAt,
    Expression<String>? categoryId,
    Expression<String>? eventId,
    Expression<String>? alarmId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (priority != null) 'priority': priority,
      if (dueAt != null) 'due_at': dueAt,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (isDone != null) 'is_done': isDone,
      if (completedAt != null) 'completed_at': completedAt,
      if (categoryId != null) 'category_id': categoryId,
      if (eventId != null) 'event_id': eventId,
      if (alarmId != null) 'alarm_id': alarmId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<TaskPriority>? priority,
    Value<DateTime?>? dueAt,
    Value<bool>? isAllDay,
    Value<bool>? isDone,
    Value<DateTime?>? completedAt,
    Value<String?>? categoryId,
    Value<String?>? eventId,
    Value<String?>? alarmId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      isAllDay: isAllDay ?? this.isAllDay,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
      categoryId: categoryId ?? this.categoryId,
      eventId: eventId ?? this.eventId,
      alarmId: alarmId ?? this.alarmId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $TasksTable.$converterpriority.toSql(priority.value),
      );
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(
        $TasksTable.$converterdueAtn.toSql(dueAt.value),
      );
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(
        $TasksTable.$convertercompletedAtn.toSql(completedAt.value),
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $TasksTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('priority: $priority, ')
          ..write('dueAt: $dueAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isDone: $isDone, ')
          ..write('completedAt: $completedAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('eventId: $eventId, ')
          ..write('alarmId: $alarmId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES tasks (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($NotesTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, taskId, body, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: $NotesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const EpochMsConverter();
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String taskId;
  final String body;
  final DateTime createdAt;
  const Note({
    required this.id,
    required this.taskId,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['body'] = Variable<String>(body);
    {
      map['created_at'] = Variable<int>(
        $NotesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Note copyWith({
    String? id,
    String? taskId,
    String? body,
    DateTime? createdAt,
  }) => Note(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String taskId,
    required String body,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? body,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $NotesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InteractionLogsTable extends InteractionLogs
    with TableInfo<$InteractionLogsTable, InteractionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InteractionLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InteractionEventType, String>
  eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (event_type IN (\'alarm_dismissed\', \'alarm_snoozed\', \'challenge_completed\', \'challenge_failed\', \'task_completed\'))',
  ).withConverter<InteractionEventType>($InteractionLogsTable.$convertereventType);
  static const VerificationMeta _alarmIdMeta = const VerificationMeta(
    'alarmId',
  );
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
    'alarm_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES alarms (id) ON DELETE SET NULL',
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES tasks (id) ON DELETE SET NULL',
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChallengeType?, String>
  challengeType = GeneratedColumn<String>(
    'challenge_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (challenge_type IS NULL OR challenge_type IN (\'maths\', \'memory\', \'phrase\', \'shake\'))',
  ).withConverter<ChallengeType?>($InteractionLogsTable.$converterchallengeTypen);
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (difficulty IS NULL OR difficulty BETWEEN 1 AND 5)',
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (duration_ms IS NULL OR duration_ms >= 0)',
  );
  static const VerificationMeta _successMeta = const VerificationMeta(
    'success',
  );
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
    'success',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (success IS NULL OR success IN (0, 1))',
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($InteractionLogsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventType,
    alarmId,
    taskId,
    challengeType,
    difficulty,
    durationMs,
    success,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'interaction_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<InteractionLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('alarm_id')) {
      context.handle(
        _alarmIdMeta,
        alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('success')) {
      context.handle(
        _successMeta,
        success.isAcceptableOrUnknown(data['success']!, _successMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InteractionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InteractionLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventType: $InteractionLogsTable.$convertereventType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}event_type'],
        )!,
      ),
      alarmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_id'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      challengeType: $InteractionLogsTable.$converterchallengeTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}challenge_type'],
        ),
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      success: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}success'],
      ),
      createdAt: $InteractionLogsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $InteractionLogsTable createAlias(String alias) {
    return $InteractionLogsTable(attachedDatabase, alias);
  }

  static TypeConverter<InteractionEventType, String> $convertereventType =
      const InteractionEventTypeConverter();
  static TypeConverter<ChallengeType, String> $converterchallengeType =
      const ChallengeTypeConverter();
  static TypeConverter<ChallengeType?, String?> $converterchallengeTypen =
      NullAwareTypeConverter.wrap($converterchallengeType);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const EpochMsConverter();
}

class InteractionLog extends DataClass implements Insertable<InteractionLog> {
  final String id;
  final InteractionEventType eventType;
  final String? alarmId;
  final String? taskId;
  final ChallengeType? challengeType;
  final int? difficulty;
  final int? durationMs;
  final bool? success;
  final DateTime createdAt;
  const InteractionLog({
    required this.id,
    required this.eventType,
    this.alarmId,
    this.taskId,
    this.challengeType,
    this.difficulty,
    this.durationMs,
    this.success,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['event_type'] = Variable<String>(
        $InteractionLogsTable.$convertereventType.toSql(eventType),
      );
    }
    if (!nullToAbsent || alarmId != null) {
      map['alarm_id'] = Variable<String>(alarmId);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || challengeType != null) {
      map['challenge_type'] = Variable<String>(
        $InteractionLogsTable.$converterchallengeTypen.toSql(challengeType),
      );
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<int>(difficulty);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || success != null) {
      map['success'] = Variable<bool>(success);
    }
    {
      map['created_at'] = Variable<int>(
        $InteractionLogsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  InteractionLogsCompanion toCompanion(bool nullToAbsent) {
    return InteractionLogsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      alarmId: alarmId == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      challengeType: challengeType == null && nullToAbsent
          ? const Value.absent()
          : Value(challengeType),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      success: success == null && nullToAbsent
          ? const Value.absent()
          : Value(success),
      createdAt: Value(createdAt),
    );
  }

  factory InteractionLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InteractionLog(
      id: serializer.fromJson<String>(json['id']),
      eventType: serializer.fromJson<InteractionEventType>(json['eventType']),
      alarmId: serializer.fromJson<String?>(json['alarmId']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      challengeType: serializer.fromJson<ChallengeType?>(json['challengeType']),
      difficulty: serializer.fromJson<int?>(json['difficulty']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      success: serializer.fromJson<bool?>(json['success']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventType': serializer.toJson<InteractionEventType>(eventType),
      'alarmId': serializer.toJson<String?>(alarmId),
      'taskId': serializer.toJson<String?>(taskId),
      'challengeType': serializer.toJson<ChallengeType?>(challengeType),
      'difficulty': serializer.toJson<int?>(difficulty),
      'durationMs': serializer.toJson<int?>(durationMs),
      'success': serializer.toJson<bool?>(success),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InteractionLog copyWith({
    String? id,
    InteractionEventType? eventType,
    Value<String?> alarmId = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    Value<ChallengeType?> challengeType = const Value.absent(),
    Value<int?> difficulty = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<bool?> success = const Value.absent(),
    DateTime? createdAt,
  }) => InteractionLog(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    alarmId: alarmId.present ? alarmId.value : this.alarmId,
    taskId: taskId.present ? taskId.value : this.taskId,
    challengeType: challengeType.present
        ? challengeType.value
        : this.challengeType,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    success: success.present ? success.value : this.success,
    createdAt: createdAt ?? this.createdAt,
  );
  InteractionLog copyWithCompanion(InteractionLogsCompanion data) {
    return InteractionLog(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      challengeType: data.challengeType.present
          ? data.challengeType.value
          : this.challengeType,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      success: data.success.present ? data.success.value : this.success,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InteractionLog(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('alarmId: $alarmId, ')
          ..write('taskId: $taskId, ')
          ..write('challengeType: $challengeType, ')
          ..write('difficulty: $difficulty, ')
          ..write('durationMs: $durationMs, ')
          ..write('success: $success, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventType,
    alarmId,
    taskId,
    challengeType,
    difficulty,
    durationMs,
    success,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InteractionLog &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.alarmId == this.alarmId &&
          other.taskId == this.taskId &&
          other.challengeType == this.challengeType &&
          other.difficulty == this.difficulty &&
          other.durationMs == this.durationMs &&
          other.success == this.success &&
          other.createdAt == this.createdAt);
}

class InteractionLogsCompanion extends UpdateCompanion<InteractionLog> {
  final Value<String> id;
  final Value<InteractionEventType> eventType;
  final Value<String?> alarmId;
  final Value<String?> taskId;
  final Value<ChallengeType?> challengeType;
  final Value<int?> difficulty;
  final Value<int?> durationMs;
  final Value<bool?> success;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InteractionLogsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.alarmId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.challengeType = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.success = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InteractionLogsCompanion.insert({
    required String id,
    required InteractionEventType eventType,
    this.alarmId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.challengeType = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.success = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventType = Value(eventType),
       createdAt = Value(createdAt);
  static Insertable<InteractionLog> custom({
    Expression<String>? id,
    Expression<String>? eventType,
    Expression<String>? alarmId,
    Expression<String>? taskId,
    Expression<String>? challengeType,
    Expression<int>? difficulty,
    Expression<int>? durationMs,
    Expression<bool>? success,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (alarmId != null) 'alarm_id': alarmId,
      if (taskId != null) 'task_id': taskId,
      if (challengeType != null) 'challenge_type': challengeType,
      if (difficulty != null) 'difficulty': difficulty,
      if (durationMs != null) 'duration_ms': durationMs,
      if (success != null) 'success': success,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InteractionLogsCompanion copyWith({
    Value<String>? id,
    Value<InteractionEventType>? eventType,
    Value<String?>? alarmId,
    Value<String?>? taskId,
    Value<ChallengeType?>? challengeType,
    Value<int?>? difficulty,
    Value<int?>? durationMs,
    Value<bool?>? success,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return InteractionLogsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      alarmId: alarmId ?? this.alarmId,
      taskId: taskId ?? this.taskId,
      challengeType: challengeType ?? this.challengeType,
      difficulty: difficulty ?? this.difficulty,
      durationMs: durationMs ?? this.durationMs,
      success: success ?? this.success,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(
        $InteractionLogsTable.$convertereventType.toSql(eventType.value),
      );
    }
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (challengeType.present) {
      map['challenge_type'] = Variable<String>(
        $InteractionLogsTable.$converterchallengeTypen.toSql(
          challengeType.value,
        ),
      );
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $InteractionLogsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InteractionLogsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('alarmId: $alarmId, ')
          ..write('taskId: $taskId, ')
          ..write('challengeType: $challengeType, ')
          ..write('difficulty: $difficulty, ')
          ..write('durationMs: $durationMs, ')
          ..write('success: $success, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $UsersTable users = $UsersTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $AlarmsTable alarms = $AlarmsTable(this);
  late final $AlarmChallengesTable alarmChallenges = $AlarmChallengesTable(
    this,
  );
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $InteractionLogsTable interactionLogs = $InteractionLogsTable(
    this,
  );
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final AlarmsDao alarmsDao = AlarmsDao(this as AppDatabase);
  late final EventsDao eventsDao = EventsDao(this as AppDatabase);
  late final TasksDao tasksDao = TasksDao(this as AppDatabase);
  late final NotesDao notesDao = NotesDao(this as AppDatabase);
  late final InteractionLogsDao interactionLogsDao = InteractionLogsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    appSettings,
    categories,
    alarms,
    alarmChallenges,
    calendarEvents,
    tasks,
    notes,
    interactionLogs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alarms',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('alarm_challenges', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calendar_events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alarms',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alarms',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('interaction_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('interaction_logs', kind: UpdateKind.update)],
    ),
  ]);
}
