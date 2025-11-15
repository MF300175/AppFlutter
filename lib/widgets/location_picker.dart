import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationPicker extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final Function(double lat, double lon, String? name) onLocationSelected;
  final Function()? onClear;

  const LocationPicker({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.onLocationSelected,
    this.onClear,
  });

  Future<void> _getCurrentLocation(BuildContext context) async {
    final location = await LocationService.instance.getCurrentLocation(context);

    if (location != null) {
      final locationName = await LocationService.instance.getLocationName(
        location.latitude,
        location.longitude,
      );

      onLocationSelected(
        location.latitude,
        location.longitude,
        locationName ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Localizacao',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (hasLocation) ...[
              if (locationName != null) ...[
                Text(
                  locationName!,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Lat: ${latitude!.toStringAsFixed(6)}, Lon: ${longitude!.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _getCurrentLocation(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Atualizar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onClear != null)
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear),
                      tooltip: 'Remover localizacao',
                    ),
                ],
              ),
            ] else
              OutlinedButton.icon(
                onPressed: () => _getCurrentLocation(context),
                icon: const Icon(Icons.location_on),
                label: const Text('Obter Localizacao Atual'),
              ),
          ],
        ),
      ),
    );
  }
}

