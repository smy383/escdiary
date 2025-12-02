import 'package:flutter/foundation.dart';
import '../models/escape_record.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';

class RecordProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AnalyticsService _analytics = AnalyticsService();

  List<EscapeRecord> _records = [];
  List<EscapeRecord> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, dynamic> _statistics = {};

  List<EscapeRecord> get records => _records;
  List<EscapeRecord> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get statistics => _statistics;

  bool get isSearching => _searchQuery.isNotEmpty;
  List<EscapeRecord> get displayRecords =>
      isSearching ? _searchResults : _records;

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await _dbService.getAllRecords();
      await _loadStatistics();
    } catch (e) {
      debugPrint('Error loading records: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStatistics() async {
    try {
      _statistics = await _dbService.getStatistics();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> addRecord(EscapeRecord record) async {
    try {
      await _dbService.insertRecord(record);
      _records.insert(0, record);
      await _loadStatistics();

      // Analytics tracking
      _analytics.logRecordCreated(
        isCleared: record.isCleared,
        playTime: record.playTime,
        averageRating: record.averageRating,
      );
      _analytics.setTotalRecordCount(_records.length);
      final clearRate = _statistics['clearRate'] ?? 0.0;
      _analytics.setClearRate(clearRate);

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding record: $e');
      rethrow;
    }
  }

  Future<void> updateRecord(EscapeRecord record) async {
    try {
      await _dbService.updateRecord(record);
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
      }
      await _loadStatistics();

      // Analytics tracking
      _analytics.logRecordUpdated();

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating record: $e');
      rethrow;
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _dbService.deleteRecord(id);
      _records.removeWhere((r) => r.id == id);
      _searchResults.removeWhere((r) => r.id == id);
      await _loadStatistics();

      // Analytics tracking
      _analytics.logRecordDeleted();
      _analytics.setTotalRecordCount(_records.length);

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting record: $e');
      rethrow;
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await _dbService.searchRecords(query);
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching records: $e');
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  EscapeRecord? getRecordById(String id) {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}
