import '../entities/diagnostic_task_model.dart';

/// Contract for persisting and retrieving plant diagnosis treatment tasks.
abstract class DiagnosticTaskRepository {
  /// Fetches all triage and treatment tasks for a specific plant plot.
  Future<List<DiagnosticTaskModel>> fetchTasksForPlant(String plantId);

  /// Saves or replaces a diagnostic task.
  Future<void> saveTask(DiagnosticTaskModel task);

  /// Saves a batch of diagnostic tasks in a single transaction.
  Future<void> saveTasks(List<DiagnosticTaskModel> tasks);

  /// Updates the completion status of a specific task.
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted);

  /// Deletes all diagnostic tasks associated with a plant.
  Future<void> deleteTasksForPlant(String plantId);
}
