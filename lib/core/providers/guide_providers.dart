import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/emergency_guide.dart';
import '../../services/offline_guide_service.dart';

/// Provider exposing the [OfflineGuideService] instance.
final offlineGuideServiceProvider = Provider<OfflineGuideService>((ref) {
  return const OfflineGuideService();
});

/// Query filter parameter object for emergency guides.
final class GuideQuery {
  const GuideQuery({this.category, this.searchQuery});
  final GuideCategory? category;
  final String? searchQuery;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuideQuery &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => category.hashCode ^ searchQuery.hashCode;
}

/// Provider fetching filtered survival guides.
final emergencyGuidesProvider =
    Provider.family<List<EmergencyGuide>, GuideQuery>((ref, query) {
      final service = ref.watch(offlineGuideServiceProvider);
      return service.getGuides(
        category: query.category,
        searchQuery: query.searchQuery,
      );
    });

/// Notifier managing checked items in the Disaster Go-Bag checklist.
class GoBagNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final service = ref.watch(offlineGuideServiceProvider);
    return service.loadCheckedGoBagItems();
  }

  Future<void> toggleItem(String item) async {
    final current = state.value ?? {};
    final updated = Set<String>.from(current);
    if (updated.contains(item)) {
      updated.remove(item);
    } else {
      updated.add(item);
    }
    state = AsyncData(updated);

    final service = ref.read(offlineGuideServiceProvider);
    await service.saveCheckedGoBagItems(updated);
  }

  Future<void> resetAll() async {
    state = const AsyncData({});
    final service = ref.read(offlineGuideServiceProvider);
    await service.saveCheckedGoBagItems({});
  }
}

/// Provider for Disaster Go-Bag checklist state.
final goBagChecklistProvider =
    AsyncNotifierProvider<GoBagNotifier, Set<String>>(GoBagNotifier.new);
