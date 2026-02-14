import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final bool isReadOnly; // Sadece görüntüleme modu için

  const MapPickerScreen({
    super.key, 
    this.initialLocation, 
    this.isReadOnly = false
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReadOnly ? "Konum Detayı" : "Konum Seç"),
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _pickedLocation);
              },
            )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Başlangıç: Varsa seçili konum, yoksa Ankara (Varsayılan)
              initialCenter: widget.initialLocation ?? const LatLng(39.9334, 32.8597),
              initialZoom: 15.0,
              // Sadece seçim modundaysa tıklamaya izin ver
              onTap: widget.isReadOnly 
                ? null 
                : (tapPosition, point) {
                    setState(() {
                      _pickedLocation = point;
                    });
                  },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.memorystation.app',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on, 
                        color: Colors.red, 
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          if (!widget.isReadOnly)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.glowShadow,
                ),
                child: Text(
                  _pickedLocation == null 
                    ? "Haritaya dokunarak bir konum işaretleyin." 
                    : "İşaretlendi: ${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
              ),
            ),
        ],
      ),
    );
  }
}