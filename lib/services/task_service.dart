import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:locus/services/manager_service.dart';
import 'package:nostr/nostr.dart';
import 'package:openpgp/openpgp.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

const storage = FlutterSecureStorage();
const KEY = "tasks_settings";

const uuid = Uuid();

class Task {
  final String id;
  final DateTime createdAt;
  String name;
  String? pgpPrivateKey;
  String nostrPrivateKey;
  Duration frequency;

  Task({
    required this.id,
    required this.name,
    required this.frequency,
    required this.pgpPrivateKey,
    required this.nostrPrivateKey,
    required this.createdAt,
  });

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      id: json["id"],
      name: json["name"],
      pgpPrivateKey: json["pgpPrivateKey"],
      nostrPrivateKey: json["nostrPrivateKey"],
      frequency: Duration(seconds: json["frequency"]),
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }

  get taskKey => "Task:$id";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "frequency": frequency.inSeconds,
      "pgpPrivateKey": pgpPrivateKey,
      "nostrPrivateKey": nostrPrivateKey,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  static Future<Task> create(
    String name,
    Duration frequency,
  ) async {
    final keyPair = await OpenPGP.generate(
      options: Options()..keyOptions = (KeyOptions()..rsaBits = 4096),
    );

    final nostrKeyPair = Keychain.generate();

    return Task(
      id: uuid.v4(),
      name: name,
      frequency: frequency,
      pgpPrivateKey: keyPair.privateKey,
      nostrPrivateKey: nostrKeyPair.private,
      createdAt: DateTime.now(),
    );
  }

  Future<bool> isRunning() async {
    final value = await storage.read(key: taskKey);

    if (value == null) {
      return false;
    }

    final data = jsonDecode(value);

    return data["runFrequency"] == frequency.inSeconds;
  }

  Future<void> start() async {
    Workmanager().registerPeriodicTask(
      id,
      WORKMANAGER_KEY,
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    await storage.write(
      key: taskKey,
      value: jsonEncode({
        "runFrequency": frequency.inSeconds,
        "startedAt": DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<void> stop() async {
    Workmanager().cancelByUniqueName(id);

    await storage.delete(key: taskKey);
  }
}

class TaskService extends ChangeNotifier {
  List<Task> _tasks;

  TaskService(List<Task> tasks) : _tasks = tasks;

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  static Future<List<Task>> get() async {
    final tasks = await storage.read(key: KEY);

    if (tasks == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(jsonDecode(tasks))
        .map((e) => Task.fromJson(e))
        .toList();
  }

  static Future<TaskService> restore() async {
    final tasks = await get();

    return TaskService(tasks);
  }

  Future<void> save() async {
    final data = jsonEncode(tasks.map((e) => e.toJson()).toList());

    await storage.write(key: KEY, value: data);
  }

  void add(Task task) {
    _tasks.add(task);

    notifyListeners();
  }

  void update() {
    notifyListeners();
  }
}
