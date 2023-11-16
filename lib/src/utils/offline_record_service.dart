import 'dart:async';
import 'dart:convert';

import 'package:pocketbase/pocketbase.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:http/http.dart' as http;

// ignore: constant_identifier_names
const _Local = 'X-Local';

typedef FallbackLoader = Future<List<RecordModel>> Function();

class OfflineRecordService extends RecordService {
  OfflineRecordService(
    PocketBase client,
    this.collectionIdOrName,
    this.database, {
    this.fallbackLoader,
  }) : super(client, collectionIdOrName);

  final SqliteDatabase database;
  final String collectionIdOrName;
  final FallbackLoader? fallbackLoader;
  late final tblName = 'collection_$collectionIdOrName';

  static final _instances = <String, OfflineRecordService>{};

  Future<void> init() async {
    if (_instances.containsKey(collectionIdOrName)) return;

    await database.execute('''
      CREATE TABLE IF NOT EXISTS $tblName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0,
        created TEXT NOT NULL,
        updated TEXT NOT NULL
      );
    ''');
    await database.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS ${tblName}_fts USING fts5(
        record_id,
        data,
        content='$tblName',
        content_rowid='id'
      );
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS ${tblName}_ai AFTER INSERT ON ${tblName} BEGIN
        INSERT INTO ${tblName}_fts(rowid, record_id, data) VALUES (new.id, new.record_id, new.data);
      END;
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS ${tblName}_ad AFTER DELETE ON ${tblName} BEGIN
        INSERT INTO ${tblName}_fts(${tblName}_fts, rowid, record_id, data) VALUES('delete', old.id, old.record_id, old.data);
      END;
    ''');
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS ${tblName}_au AFTER UPDATE ON ${tblName} BEGIN
        INSERT INTO ${tblName}_fts(${tblName}_fts, rowid, record_id, data) VALUES('delete', old.id, old.record_id, old.data);
        INSERT INTO ${tblName}_fts(rowid, record_id, data) VALUES (new.id, new.record_id, new.data);
      END;
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS ${tblName}_crdt (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        row_id TEXT NOT NULL,
        column TEXT NOT NULL,
        value TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL
      );
    ''');
    _instances[collectionIdOrName] = this;
  }

  Future<List<RecordModel>> getLocalItems() async {
    final result =
        await database.getAll('SELECT * FROM $tblName WHERE deleted = 0');
    return result
        .map((e) => jsonDecode(e['data'] as String))
        .map((e) => RecordModel.fromJson(e))
        .toList();
  }

  Future<RecordModel?> getLocalItem(String id) async {
    final result = await database
        .getOptional('SELECT * FROM $tblName WHERE record_id = ?', [id]);
    if (result == null) return null;
    return RecordModel.fromJson(jsonDecode(result['data'] as String));
  }

  Future<void> saveLocal(RecordModel item, {bool synced = false}) async {
    final data = jsonEncode(item.toJson());
    final result = await database
        .getAll('SELECT * FROM $tblName WHERE record_id = ?', [item.id]);
    if (result.isEmpty) {
      await database.execute(
        'INSERT INTO $tblName (record_id, data, synced, created, updated) VALUES (?, ?, ?, ?, ?)',
        [item.id, data, synced, item.created, item.updated],
      );
    } else {
      await database.execute(
        'UPDATE $tblName SET data = ?, synced = ?, updated = ? WHERE record_id = ?',
        [data, synced, item.updated, item.id],
      );
    }
  }

  Future<void> saveLocalItems(List<RecordModel> items,
      {bool synced = false}) async {
    final existing = <String, bool>{};
    for (final item in items) {
      final result = await database.getOptional(
        'SELECT * FROM $tblName WHERE record_id = ?',
        [item.id],
      );
      existing[item.id] = result != null;
    }
    final List<List<Object?>> existingBatch = [], newBatch = [];
    for (final item in existing.entries) {
      final record = items.firstWhere((e) => e.id == item.key);
      final data = jsonEncode(record.toJson());
      if (item.value) {
        existingBatch.add([data, record.updated, synced, record.id]);
      } else {
        newBatch.add([record.id, data, synced, record.created, record.updated]);
      }
    }
    await database.executeBatch(
        'INSERT INTO $tblName (record_id, data, synced, created, updated) VALUES (?, ?, ?, ?, ?)',
        newBatch);
    await database.executeBatch(
        'UPDATE $tblName SET data = ?, updated = ?, synced = ? WHERE record_id = ?',
        existingBatch);
  }

  Future<void> deleteLocalItems() async {
    await database.execute('DELETE FROM $tblName');
  }

  Future<void> deleteLocalItem(String id, {bool tombstone = true}) async {
    if (tombstone) {
      await database.execute(
        'UPDATE $tblName SET deleted = 1 WHERE record_id = ?',
        [id],
      );
    } else {
      await database.execute(
        'DELETE FROM $tblName WHERE record_id = ?',
        [id],
      );
    }
  }

  Future<void> setSynced(RecordModel item) async {
    await database.execute(
      'UPDATE $tblName SET synced = 1 WHERE record_id = ?',
      [item.id],
    );
  }

  Future<void Function()> watchInit() async {
    final cancel = await subscribe('*', (e) async {
      switch (e.action) {
        case 'create':
          if (e.record != null) {
            await saveLocal(e.record!);
          }
          break;
        case 'update':
          if (e.record != null) {
            await saveLocal(e.record!);
          }
          break;
        case 'delete':
          if (e.record != null) {
            await deleteLocalItem(e.record!.id);
          }
          break;
        default:
      }
    });
    await sync();
    return cancel;
  }

  Stream<List<RecordModel>> watchLocal() async* {
    yield await getLocalItems();
    await for (final _ in database.updates) {
      yield await getLocalItems();
    }
  }

  Future<void> addCrdt(RecordModel model, CrdtAction action) async {
    final timestamp = DateTime.now().toIso8601String();
    final data =
        action == CrdtAction.delete ? {'id': model.id} : model.toJson();
    for (final entry in data.entries) {
      await database.execute(
        'INSERT INTO ${tblName}_crdt (row_id, column, value, action, timestamp) VALUES (?, ?, ?, ?, ?)',
        [model.id, entry.key, entry.value, action.name, timestamp],
      );
    }
  }

  Future<void> removeCrdt(int id) async {
    await database.execute(
      'DELETE FROM ${tblName}_crdt WHERE id = ?',
      [id],
    );
  }

  Future<void> sync() async {
    final local = await getLocalItems();
    if (local.isEmpty) {
      try {
        final remoteRecords = await getFullList();
        await saveLocalItems(remoteRecords, synced: true);
      } catch (e) {
        print('Sync full error: $e');
        final fallback = await fallbackLoader?.call();
        if (fallback != null) {
          await saveLocalItems(fallback, synced: true);
        }
      }
    }
    String? lastUpdated;
    final crdtRecords = await database.getAll('SELECT * FROM ${tblName}_crdt');
    if (crdtRecords.isNotEmpty) {
      // Get oldest timestamp
      final oldestTimestamp = crdtRecords
          .map((e) => DateTime.parse(e['timestamp']))
          .reduce((v, e) => v.isBefore(e) ? v : e);
      lastUpdated = oldestTimestamp.toIso8601String();
    }
    // Group by timestamp
    final timestamps = crdtRecords.map((e) => e['timestamp']).toSet();
    for (final timestamp in timestamps) {
      final related =
          crdtRecords.where((e) => e['timestamp'] == timestamp).toList();
      final rowIds = related.map((e) => e['row_id']).toSet();

      // Preform actions for each id
      for (final id in rowIds) {
        final data = <String, dynamic>{};
        final rowItems = related.where((e) => e['row_id'] == id);
        for (final entry in rowItems) {
          data[entry['column']] = entry['value'];
        }
        // TODO: check if still deleted
        final record = RecordModel.fromJson(data);
        try {
          final action = CrdtAction.values
              .firstWhere((e) => e.name == rowItems.first['action']);
          final headers = {_Local: 'true'};
          switch (action) {
            case CrdtAction.create:
              await create(body: record.toJson(), headers: headers);
              break;
            case CrdtAction.update:
              await update(record.id, body: record.toJson(), headers: headers);
              break;
            case CrdtAction.delete:
              await delete(record.id, headers: headers);
              await deleteLocalItem(record.id, tombstone: false);
              break;
          }
          for (final item in rowItems) {
            await removeCrdt(item['id']);
          }
        } catch (e) {
          print('Crdt sync error: $e');
        }
      }
    }
    if (local.isNotEmpty) {
      try {
        final remoteRecords = await getFullList(
          filter: lastUpdated == null ? null : "updated > '$lastUpdated'",
        );
        await saveLocalItems(remoteRecords, synced: true);
      } catch (e) {
        print('Sync partial error: $e');
      }
    }
  }

  @override
  Future<RecordModel> create({
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    List<http.MultipartFile> files = const [],
    Map<String, String> headers = const {},
    String? expand,
    String? fields,
  }) async {
    final sync = headers[_Local] == 'true';
    try {
      final result = await super.create(
        body: body,
        query: query,
        files: files,
        headers: headers,
        expand: expand,
        fields: fields,
      );
      await saveLocal(result, synced: true);
      return result;
    } catch (e) {
      if (e is ClientException) {
        if (e.statusCode != 400 && e.statusCode != 403) {
          if (!sync && files.isEmpty) {
            final record = RecordModel.fromJson(body);
            await addCrdt(record, CrdtAction.create);
            return record;
          }
        }
      }
    }
    throw Exception('Failed to create record');
  }

  @override
  Future<RecordModel> update(
    String id, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    List<http.MultipartFile> files = const [],
    Map<String, String> headers = const {},
    String? expand,
    String? fields,
  }) async {
    final sync = headers[_Local] == 'true';
    try {
      final result = await super.update(
        id,
        body: body,
        query: query,
        files: files,
        headers: headers,
        expand: expand,
        fields: fields,
      );
      await saveLocal(result, synced: true);
      return result;
    } catch (e) {
      if (e is ClientException) {
        if (e.statusCode != 400 && e.statusCode != 403) {
          if (!sync && files.isEmpty) {
            final record = RecordModel.fromJson(body);
            await addCrdt(record, CrdtAction.update);
            return record;
          }
        }
      }
    }
    throw Exception('Failed to update record');
  }

  @override
  Future<void> delete(
    String id, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final sync = headers[_Local] == 'true';
    try {
      await super.delete(
        id,
        body: body,
        query: query,
        headers: headers,
      );
      await deleteLocalItem(id, tombstone: false);
    } catch (e) {
      if (e is ClientException) {
        if (e.statusCode != 400 && e.statusCode != 403) {
          if (!sync) {
            final record = RecordModel(id: id);
            await deleteLocalItem(id);
            await addCrdt(record, CrdtAction.delete);
            return;
          }
        }
      }
    }
    throw Exception('Failed to delete record');
  }

  Future<List<RecordModel>> searchLocal(String query) async {
    final result = await database.getAll(
        'SELECT * FROM ${tblName}_fts WHERE ${tblName}_fts MATCH ? ORDER BY rank',
        [query]);
    return result
        .map((e) => jsonDecode(e['data']))
        .map((e) => RecordModel.fromJson(e))
        .toList();
  }

  // @override
  // Future<List<RecordModel>> getFullList({
  //   int batch = 500,
  //   String? expand,
  //   String? filter,
  //   String? sort,
  //   String? fields,
  //   Map<String, dynamic> query = const {},
  //   Map<String, String> headers = const {},
  // }) async {
  //   final local = headers[_Local] == 'true';
  //   if (!headers.containsKey(_Local)) {
  //     return super.getFullList(
  //       batch: batch,
  //       expand: expand,
  //       filter: filter,
  //       sort: sort,
  //       fields: fields,
  //       query: query,
  //       headers: headers,
  //     );
  //   }
  //   try {
  //     final remote = await super.getFullList(
  //       batch: batch,
  //       expand: expand,
  //       filter: filter,
  //       sort: sort,
  //       fields: fields,
  //       query: query,
  //       headers: headers,
  //     );
  //     await saveLocalItems(remote);
  //     return remote;
  //   } catch (e) {
  //     if (e is ClientException) {
  //       if (e.statusCode != 400 && e.statusCode != 403) {
  //         if (!local) {
  //           return getLocalItems();
  //         }
  //       }
  //     }
  //   }
  //   throw Exception('Failed to get full list');
  // }
}

enum CrdtAction {
  create,
  update,
  delete,
}

extension PocketBaseUtils on PocketBase {
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<OfflineRecordService> offlineCollection(
    SqliteDatabase database,
    String collectionIdOrName, {
    FallbackLoader? fallbackLoader,
  }) async {
    final service = OfflineRecordService(
      this,
      collectionIdOrName,
      database,
      fallbackLoader: fallbackLoader,
    );
    await service.init();
    return service;
  }
}
