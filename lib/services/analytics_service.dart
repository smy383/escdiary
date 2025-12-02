import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // App lifecycle events
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Record events
  Future<void> logRecordCreated({
    required bool isCleared,
    required int playTime,
    required double averageRating,
  }) async {
    await _analytics.logEvent(
      name: 'record_created',
      parameters: {
        'is_cleared': isCleared,
        'play_time': playTime,
        'average_rating': averageRating,
      },
    );
  }

  Future<void> logRecordUpdated() async {
    await _analytics.logEvent(name: 'record_updated');
  }

  Future<void> logRecordDeleted() async {
    await _analytics.logEvent(name: 'record_deleted');
  }

  // Screen view events
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Search events
  Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }

  // Statistics view
  Future<void> logStatisticsViewed() async {
    await _analytics.logEvent(name: 'statistics_viewed');
  }

  // User properties
  Future<void> setTotalRecordCount(int count) async {
    await _analytics.setUserProperty(
      name: 'total_records',
      value: count.toString(),
    );
  }

  Future<void> setClearRate(double rate) async {
    await _analytics.setUserProperty(
      name: 'clear_rate',
      value: rate.toStringAsFixed(1),
    );
  }
}
