import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'models/poi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<POIType> _visibleTypes = POIType.values.toSet();
  
  bool _isFilterPanelExpanded = false;

  void _updateVisibleTypes(Set<POIType> newTypes) {
    setState(() {
      _visibleTypes = newTypes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapScreen(
            visibleTypes: _visibleTypes,
            onTypesChanged: _updateVisibleTypes,
          ),

          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isFilterPanelExpanded ? 250 : 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.2),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  IconButton(
                    icon: Icon(_isFilterPanelExpanded 
                      ? Icons.arrow_back 
                      : Icons.menu),
                    onPressed: () {
                      setState(() {
                        _isFilterPanelExpanded = !_isFilterPanelExpanded;
                      });
                    },
                  ),

                  const Divider(),

                  Expanded(
                    child: _isFilterPanelExpanded
                        ? _buildExpandedFilterPanel()
                        : _buildCollapsedFilterPanel(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedFilterPanel() {
    return ListView(
      children: [
        _buildFilterIcon(POIType.restaurant),
        _buildFilterIcon(POIType.cafe),
        _buildFilterIcon(POIType.shop),
        _buildFilterIcon(POIType.school),
        _buildFilterIcon(POIType.health),
        _buildFilterIcon(POIType.hotel),
        _buildFilterIcon(POIType.fuel),
        _buildFilterIcon(POIType.other),
      ],
    );
  }

  Widget _buildExpandedFilterPanel() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Filtruj punkty:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        
        // Przycisk "Zaznacz wszystkie"
        TextButton(
          onPressed: () {
            _updateVisibleTypes(POIType.values.toSet());
          },
          child: const Text('Zaznacz wszystkie'),
        ),
        
        // Przycisk "Odznacz wszystkie"
        TextButton(
          onPressed: () {
            _updateVisibleTypes(<POIType>{});
          },
          child: const Text('Odznacz wszystkie'),
        ),
        
        const Divider(),
        
        // Lista typów z checkboxami
        ...POIType.values.map((type) => CheckboxListTile(
          title: Row(
            children: [
              Icon(type.icon, color: type.color, size: 20),
              const SizedBox(width: 8),
              Text(type.displayName),
            ],
          ),
          value: _visibleTypes.contains(type),
          onChanged: (bool? value) {
            final newTypes = Set<POIType>.from(_visibleTypes);
            if (value == true) {
              newTypes.add(type);
            } else {
              newTypes.remove(type);
            }
            _updateVisibleTypes(newTypes);
          },
          secondary: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: type.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              type.icon,
              color: Colors.white,
              size: 14,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildFilterIcon(POIType type) {
    bool isActive = _visibleTypes.contains(type);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? type.color : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: isActive 
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Icon(
            type.icon,
            color: isActive ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        onPressed: () {
          final newTypes = Set<POIType>.from(_visibleTypes);
          if (newTypes.contains(type)) {
            newTypes.remove(type);
          } else {
            newTypes.add(type);
          }
          _updateVisibleTypes(newTypes);
        },
      ),
    );
  }
}