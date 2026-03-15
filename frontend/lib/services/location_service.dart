import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';

class LocationService {
  static final ApiService _api = ApiService();

  /// Update repairman current location (POST /api/location/update)
  static Future<Map<String, dynamic>> updateRepairmanLocation(
    double latitude,
    double longitude,
  ) async {
    final response = await _api.post('/api/location/update', {
      'latitude': latitude,
      'longitude': longitude,
    });
    return response;
  }

  /// Get repairman location by booking ID (GET /api/location/:bookingId)
  static Future<Map<String, dynamic>> getRepairmanLocationByBooking(
    String bookingId,
  ) async {
    final response = await _api.get('/api/location/$bookingId');
    return response;
  }

  /// Get current device location (with permission handling)
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
