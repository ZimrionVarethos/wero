import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Cross-platform device location service using standard Geolocation API.
class LocationService {
  const LocationService();

  /// Retrieve device's current GPS / browser coordinates.
  Future<LatLng> determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi (GPS) pada perangkat belum aktif.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin akses lokasi diblokir permanen. Aktifkan di pengaturan browser/perangkat.',
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    return LatLng(pos.latitude, pos.longitude);
  }
}
