import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  bool _locationServiceEnabled = false;

  Future<void> initialize() async {
    try {
      _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Erro ao verificar GPS: $e');
      _locationServiceEnabled = false;
    }
  }

  bool get isLocationServiceEnabled => _locationServiceEnabled;

  Future<Position?> getCurrentLocation(BuildContext context) async {
    if (!_locationServiceEnabled) {
      final enabled = await Geolocator.openLocationSettings();
      if (!enabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS nao esta habilitado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permissao necessaria'),
              content: const Text(
                'Precisamos da permissao de localizacao para associar tarefas a lugares.\n\n'
                'Deseja abrir as configuracoes?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Configuracoes'),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissao de localizacao negada permanentemente. Habilite nas configuracoes.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        await openAppSettings();
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('GPS falhou, tentando Network Location');

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e2) {
        print('Localizacao nao disponivel: $e2');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nao foi possivel obter localizacao. Verifique o GPS.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    }
  }

  Future<String?> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.subThoroughfare != null) place.subThoroughfare,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        return address.isNotEmpty ? address : null;
      }

      return null;
    } catch (e) {
      print('Erro no geocoding: $e');
      return null;
    }
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

