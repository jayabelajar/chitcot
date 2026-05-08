import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get nickname => text().withLength(min: 1, max: 64)();
  TextColumn get publicKey => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get senderId => text().references(Users, #id)();
  TextColumn get receiverId => text().nullable().references(Users, #id)();
  TextColumn get ciphertext => text()();
  IntColumn get ttl => integer().withDefault(const Constant(0))();
  IntColumn get hopCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text()();
  TextColumn get direction => text()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RelayQueue extends Table {
  TextColumn get messageId => text().references(Messages, #id)();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {messageId};
}

class SeenMessages extends Table {
  TextColumn get messageId => text()();
  DateTimeColumn get seenAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {messageId};
}

@DriftDatabase(tables: [Users, Messages, RelayQueue, SeenMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'bluemesh_chat.sqlite'));
    return NativeDatabase(file);
  });
}
