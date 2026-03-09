// models/poi.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class POI {
  final String id;
  final String name;
  final LatLng position;
  final POIType type;
  final String? address;
  final Map<String, dynamic>? tags;

  POI({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    this.address,
    this.tags,
  });

  factory POI.fromOverpassJson(Map<String, dynamic> json) {
    // Parsowanie danych z Overpass API
    double lat = json['lat'] ?? json['center']?['lat'] ?? 0.0;
    double lon = json['lon'] ?? json['center']?['lon'] ?? 0.0;
    
    String name = json['tags']?['name'] ?? 'Bez nazwy';
    
    POIType type = POIType.other;
    if (json['tags'] != null) {
      if (json['tags']['amenity'] == 'restaurant') type = POIType.restaurant;
      else if (json['tags']['amenity'] == 'cafe') type = POIType.cafe;
      else if (json['tags']['shop'] != null) type = POIType.shop;
      else if (json['tags']['amenity'] == 'school') type = POIType.school;
      else if (json['tags']['amenity'] == 'hospital' || json['tags']['amenity'] == 'clinic') type = POIType.health;
      else if (json['tags']['tourism'] == 'hotel') type = POIType.hotel;
      else if (json['tags']['amenity'] == 'fuel') type = POIType.fuel;
    }

    return POI(
      id: json['id'].toString(),
      name: name,
      position: LatLng(lat, lon),
      type: type,
      address: json['tags']?['addr:full'] ?? json['tags']?['address'] ?? '',
      tags: json['tags'],
    );
  }
}

enum POIType {
  restaurant,
  cafe,
  shop,
  school,
  health,
  hotel,
  fuel,
  other;
  
  // Dla łatwiejszego wyświetlania
  String get displayName {
    switch (this) {
      case POIType.restaurant: return 'Restauracje';
      case POIType.cafe: return 'Kawiarnie';
      case POIType.shop: return 'Sklepy';
      case POIType.school: return 'Szkoły';
      case POIType.health: return 'Opieka zdrowotna';
      case POIType.hotel: return 'Hotele';
      case POIType.fuel: return 'Stacje paliw';
      case POIType.other: return 'Inne';
    }
  }
  
  // Dla ikon
  IconData get icon {
    switch (this) {
      case POIType.restaurant: return Icons.restaurant;
      case POIType.cafe: return Icons.local_cafe;
      case POIType.shop: return Icons.shopping_bag;
      case POIType.school: return Icons.school;
      case POIType.health: return Icons.local_hospital;
      case POIType.hotel: return Icons.hotel;
      case POIType.fuel: return Icons.local_gas_station;
      case POIType.other: return Icons.place;
    }
  }
  
  // Kolor markera
  Color get color {
    switch (this) {
      case POIType.restaurant: return Colors.red;
      case POIType.cafe: return Colors.brown;
      case POIType.shop: return Colors.blue;
      case POIType.school: return Colors.orange;
      case POIType.health: return Colors.green;
      case POIType.hotel: return Colors.purple;
      case POIType.fuel: return Colors.amber;
      case POIType.other: return Colors.grey;
    }
  }
}