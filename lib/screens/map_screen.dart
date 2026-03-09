import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/poi.dart';

class MapScreen extends StatefulWidget {
  final Set<POIType>? visibleTypes; 
  final Function(Set<POIType>)?
  onTypesChanged; 

  const MapScreen({super.key, this.visibleTypes, this.onTypesChanged});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = false;
  bool _isSearchingPOI = false;
  LatLng? _currentPosition;

  List<POI> _poiList = [];

  bool _showSearchRadius = false;
  final double _searchRadiusMeters = 500;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _centerOnUserLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Potrzebuję dostępu do lokalizacji');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Uprawnienia do lokalizacji są na stałe zablokowane');
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;
        _showSearchRadius = true; 
      });

      _mapController.move(newPosition, 15.0);

      await _searchPOI(newPosition);
    } catch (e) {
      _showSnackBar('Nie udało się pobrać lokalizacji: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testOverpassAPI(LatLng center) async {
    try {
      String testQuery =
          '''
      [out:json];
      node(around:500,${center.latitude},${center.longitude})["amenity"="restaurant"];
      out body;
    ''';

      print('Test query: $testQuery');

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': testQuery},
      );

      print('Status code: ${response.statusCode}');
      print(
        'Response body preview: ${response.body.substring(0, min(200, response.body.length))}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Elements found: ${data['elements']?.length ?? 0}');
      }
    } catch (e) {
      print('Test error: $e');
    }
  }

  Future<void> _searchPOI(LatLng center) async {
    print('===== DEBUG OVERPASS API =====');
    print('Latitude: ${center.latitude}');
    print('Longitude: ${center.longitude}');
    print('Radius: $_searchRadiusMeters');
    setState(() {
      _isSearchingPOI = true;
    });

    try {
      String overpassQuery =
          '''
      [out:json];
      (
        node["amenity"="restaurant"](around:${_searchRadiusMeters.toInt()},${center.latitude},${center.longitude});
        node["amenity"="cafe"](around:${_searchRadiusMeters.toInt()},${center.latitude},${center.longitude});
        node["shop"](around:${_searchRadiusMeters.toInt()},${center.latitude},${center.longitude});
        node["amenity"="school"](around:${_searchRadiusMeters.toInt()},${center.latitude},${center.longitude});
        node["amenity"="hospital"](around:${_searchRadiusMeters.toInt()},${center.latitude},${center.longitude});
        node["amenity"="clinic"](around:${_searchRadiusMeters.toInt()},${center.latitude},${center.longitude});
        node["tourism"="hotel"](around:${_searchRadiusMeters.toInt()},${center.latitude},${center.longitude});
        node["amenity"="fuel"](around:${_searchRadiusMeters.toInt()},${center.latitude},${center.longitude});
      );
      out body;
    ''';

      print('Wysyłam zapytanie do Overpass API...');

      // Ważne: używamy application/x-www-form-urlencoded
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': overpassQuery},
      );

      print('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Otrzymano dane: ${data.keys}');

        final List<dynamic> elements = data['elements'] ?? [];
        print('Liczba elementów: ${elements.length}');

        List<POI> foundPOIs = [];

        for (var element in elements) {
          try {
            final poi = POI.fromOverpassJson(element);
            foundPOIs.add(poi);
            print('Dodano POI: ${poi.name} (${poi.type})');
          } catch (e) {
            print('Błąd parsowania elementu: $e');
            print('Problematic element: $element');
          }
        }

        setState(() {
          _poiList = foundPOIs;
        });

        _showSnackBar('Znaleziono ${foundPOIs.length} punktów w okolicy');
      } else {
        print('Błąd odpowiedzi: ${response.statusCode}');
        print('Treść błędu: ${response.body}');
        throw Exception('Błąd połączenia z API');
      }
    } catch (e) {
      print('Wyjątek w _searchPOI: $e');
      _showSnackBar('Błąd podczas wyszukiwania: $e');
    } finally {
      setState(() {
        _isSearchingPOI = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(52.2297, 21.0122),
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
              subdomains: const ['a', 'b', 'c'],
            ),

            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            if (_poiList.isNotEmpty && widget.visibleTypes != null)
              MarkerLayer(
                markers: _poiList
                    .where((poi) => widget.visibleTypes!.contains(poi.type))
                    .map(
                      (poi) => Marker(
                        point: poi.position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            _showPOIDetails(poi);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: poi.type.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              poi.type.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),

        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _isLoading ? null : _centerOnUserLocation,
            backgroundColor: Colors.blue,
            child: _isLoading || _isSearchingPOI
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.my_location, color: Colors.white),
          ),
        ),

        if (_isSearchingPOI)
          Positioned(
            top: 16,
            left: 86,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Szukam punktów w okolicy...'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showPOIDetails(POI poi) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(poi.type.icon, color: poi.type.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Typ: ${poi.type.displayName}'),
            if (poi.address != null && poi.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Adres: ${poi.address}'),
            ],
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Nawiguj do tego punktu
                  _mapController.move(poi.position, 16.0);
                  Navigator.pop(context);
                },
                child: const Text('Pokaż na mapie'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
