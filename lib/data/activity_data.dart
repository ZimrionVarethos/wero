import '../models/activity.dart';
import 'image_sources.dart';

/// Placeholder activity list used by ActivityScreen.
/// Replace with an API call when a backend is available.
const List<Activity> allActivities = [
  Activity(
    name: 'Swimming',
    imageUrl: ImageSources.activitySwimming,
    calories: 430,
    category: ActivityCategory.popular,
  ),
  Activity(
    name: 'Playing Tennis',
    imageUrl: ImageSources.activityTennis,
    calories: 430,
    category: ActivityCategory.popular,
  ),
  Activity(
    name: 'Running',
    imageUrl: ImageSources.activityRunning,
    calories: 500,
    category: ActivityCategory.intensive,
  ),
  Activity(
    name: 'Cycling',
    imageUrl: ImageSources.activityCycling,
    calories: 400,
    category: ActivityCategory.moderate,
  ),
];
