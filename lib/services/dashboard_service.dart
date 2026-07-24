import 'api_service.dart';

/// Fetches aggregated dashboard data in a single API call.
class DashboardService {
  /// Get dashboard data: user name, daily summary, today's meals.
  static Future<Map<String, dynamic>> getDashboardData([String? date]) async {
    final endpoint = date != null ? '/dashboard?date=$date' : '/dashboard';
    return await ApiService.get(endpoint);
  }
}
