import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/plant_model.dart';
import '../../domain/repositories/plant_repository.dart';

/// SQLite-backed production implementation of [PlantRepository].
///
/// Persists crop profiles and plot telemetry locally on Android, iOS, and tablets.
class SqlitePlantRepository implements PlantRepository {
  SqlitePlantRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  List<PlantModel>? _cachedPlants;

  List<PlantModel> get currentPlants => _cachedPlants ?? const <PlantModel>[];

  @override
  Future<List<PlantModel>> fetchAllPlants() async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'plants',
      orderBy: 'rowid ASC',
    );
    if (results.isEmpty) {
      _cachedPlants = const <PlantModel>[];
      return const <PlantModel>[];
    }
    _cachedPlants = results.map(PlantModel.fromMap).toList();
    return _cachedPlants!;
  }

  @override
  Future<PlantModel?> fetchPlantById(String id) async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }
    return PlantModel.fromMap(results.first);
  }

  @override
  Future<void> savePlant(PlantModel plant) async {
    final db = await _appDatabase.database;
    await db.insert(
      'plants',
      plant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final updated = List<PlantModel>.from(currentPlants);
    final idx = updated.indexWhere((p) => p.id == plant.id);
    if (idx >= 0) {
      updated[idx] = plant;
    } else {
      updated.add(plant);
    }
    _cachedPlants = updated;
  }

  @override
  Future<void> deletePlant(String id) async {
    final db = await _appDatabase.database;
    await db.delete(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
    _cachedPlants = currentPlants.where((p) => p.id != id).toList();
  }
}
