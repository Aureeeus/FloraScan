import '../entities/plant_model.dart';

/// Contract for plant data persistence and querying.
///
/// Implemented by mock repositories during UI prototyping and can be
/// seamlessly replaced with SQLite/Drift or remote REST/gRPC implementations.
abstract interface class PlantRepository {
  /// Retrieves all crops currently registered in the system.
  Future<List<PlantModel>> fetchAllPlants();

  /// Retrieves a specific crop by unique identifier.
  Future<PlantModel?> fetchPlantById(String id);

  /// Registers a newly monitored crop plot.
  Future<void> savePlant(PlantModel plant);

  /// Removes a crop plot from observation.
  Future<void> deletePlant(String id);
}
