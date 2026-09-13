import 'history_service.dart';

class RecentSearches {
  static Future<List<String>> load() => HistoryService.getSearchHistory();
  static Future<void> add(String query) => HistoryService.addSearchQuery(query);
  static Future<void> remove(String query) =>
      HistoryService.removeSearchQuery(query);
  static Future<void> clear() => HistoryService.clearSearchHistory();
}
