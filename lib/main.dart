import 'package:flutter/material.dart';
import 'screens/map_screen.dart';

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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// MAPA
          const MapScreen(),

          /// OVERLAY SIDEBAR
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,

            child: Container(
              width: 70,
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

                  /// Menu icon (jeśli kiedyś dodasz drawer / menu animowane)
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      // Możesz tutaj dodać animowany panel
                    },
                  ),

                  const Divider(),

                  IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () {},
                  ),

                  IconButton(
                    icon: const Icon(Icons.restaurant),
                    onPressed: () {},
                  ),

                  IconButton(
                    icon: const Icon(Icons.store),
                    onPressed: () {},
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}