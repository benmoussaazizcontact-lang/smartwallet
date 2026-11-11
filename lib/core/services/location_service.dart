import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude, this.address});

  final double latitude;
  final double longitude;
  final String? address;
}

class LocationService {
  const LocationService();

  Future<bool> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<GeoPoint?> currentPoint() async {
    final allowed = await ensurePermission();
    if (!allowed) return null;
    final position = await Geolocator.getCurrentPosition();
    String? address;
    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        address = [
          p.street,
          p.locality,
          p.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (_) {
      address = null;
    }
    return GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  Future<String?> addressFor(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return null;
      final p = places.first;
      return [p.street, p.locality, p.country]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
    } catch (_) {
      return null;
    }
  }
}
