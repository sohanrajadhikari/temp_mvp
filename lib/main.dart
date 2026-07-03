import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

void main() {
  runApp(const BusBinApp());
}

class BusBinApp extends StatelessWidget {
  const BusBinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusBin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1), // Indigo
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        cardColor: const Color(0xFF1E293B), // Slate 800
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981), // Emerald
          surface: Color(0xFF1E293B),
          background: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// Dynamic Splash Screen displaying the logo.jpg beautifully
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    _controller.forward();

    // Transition to main screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Container with glassmorphic styling and shadow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback in case logo.jpg is not found or loaded yet
                      return Container(
                        color: const Color(0xFF1E293B),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          size: 80,
                          color: Color(0xFF6366F1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'BusBin',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kathmandu\'s Smart Bus Tracker',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simulated Bus Model representing current live state of each bus
class Bus {
  final String id;
  final String busNumber;
  int currentSegmentIndex;
  double progress; // 0.0 to 1.0 along the current road segment
  int direction; // 1 = forward (Ratnapark to Budhanilkantha), -1 = backward
  int passengerCount;
  LatLng currentPosition;

  Bus({
    required this.id,
    required this.busNumber,
    required this.currentSegmentIndex,
    required this.progress,
    required this.direction,
    required this.passengerCount,
    required this.currentPosition,
  });

  String get occupancyStatus {
    if (passengerCount >= 30) return 'Full';
    if (passengerCount >= 20) return 'Standing Only';
    return 'Seats Available';
  }

  Color get occupancyColor {
    if (passengerCount >= 30) return const Color(0xFFEF4444); // Red
    if (passengerCount >= 20) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Emerald Green
  }

  int get revenue => passengerCount * 25; // 25 NPR per passenger
}

/// Main Screen with custom dual-tab navigation and sync'd simulation
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _simulationTimer;
  final Random _random = Random();
  
  // Selected bus for details card
  Bus? _selectedBus;

  // Fixed Kathmandu route coordinates: Ratnapark to Budhanilkantha via Maharajgunj
  final List<LatLng> _routePoints = [
    const LatLng(27.7052, 85.3148), // Ratnapark
    const LatLng(27.7086, 85.3155), // Jamal
    const LatLng(27.7160, 85.3135), // Lainchaur
    const LatLng(27.7230, 85.3160), // Lazimpat
    const LatLng(27.7295, 85.3210), // Lazimpat North
    const LatLng(27.7375, 85.3310), // Maharajgunj (Chakrapath Outer)
    const LatLng(27.7405, 85.3355), // Maharajgunj Chowk
    const LatLng(27.7510, 85.3440), // Golfutar Chowk
    const LatLng(27.7610, 85.3520), // Hattigaunda
    const LatLng(27.7680, 85.3570), // Hepali Height
    const LatLng(27.7745, 85.3615), // Budhanilkantha Chowk
    const LatLng(27.7788, 85.3644), // Budhanilkantha Temple (End Point)
  ];

  // Landmark names corresponding to the indices
  final List<String> _landmarkNames = [
    'Ratnapark',
    'Jamal',
    'Lainchaur',
    'Lazimpat',
    'Lazimpat North',
    'Maharajgunj',
    'Maharajgunj Chowk',
    'Golfutar',
    'Hattigaunda',
    'Hepali Height',
    'Budhanilkantha Chowk',
    'Budhanilkantha Temple',
  ];

  // Initialize two active simulated buses
  late List<Bus> _buses;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial bus setups
    _buses = [
      Bus(
        id: 'B1',
        busNumber: 'Ba 3 Kha 4050',
        currentSegmentIndex: 0,
        progress: 0.0,
        direction: 1,
        passengerCount: 18,
        currentPosition: const LatLng(27.7052, 85.3148),
      ),
      Bus(
        id: 'B2',
        busNumber: 'Ba 4 Kha 9912',
        currentSegmentIndex: 10,
        progress: 0.0,
        direction: -1,
        passengerCount: 28,
        currentPosition: const LatLng(27.7745, 85.3615),
      ),
    ];

    // Automatically select the first bus by default
    _selectedBus = _buses[0];

    // Start Simulation Loop (Updates every 1 second)
    _startSimulation();
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        for (var bus in _buses) {
          // 1. Update position progress (incrementally move between coordinates)
          bus.progress += 0.08; // speed factor

          if (bus.progress >= 1.0) {
            bus.progress = 0.0;
            bus.currentSegmentIndex += bus.direction;

            // Boundary Checks (Reverse direction at ends)
            if (bus.currentSegmentIndex >= _routePoints.length - 1) {
              bus.currentSegmentIndex = _routePoints.length - 2;
              bus.direction = -1;
            } else if (bus.currentSegmentIndex < 0) {
              bus.currentSegmentIndex = 0;
              bus.direction = 1;
            }
          }

          // Calculate current exact position by interpolating
          final int startIdx = bus.currentSegmentIndex;
          final int endIdx = startIdx + 1;
          final LatLng startPt = _routePoints[startIdx];
          final LatLng endPt = _routePoints[endIdx];

          final double lat = startPt.latitude + (endPt.latitude - startPt.latitude) * bus.progress;
          final double lng = startPt.longitude + (endPt.longitude - startPt.longitude) * bus.progress;
          bus.currentPosition = LatLng(lat, lng);

          // 2. Fluctuuate passenger count occasionally
          if (_random.nextDouble() < 0.3) {
            // Random shift between -5 and +5
            int shift = _random.nextInt(11) - 5;
            bus.passengerCount = (bus.passengerCount + shift).clamp(5, 35);
          }
        }
      });
    });
  }

  // Helper to compute ETA to next landmark based on speed/progress
  String _calculateETA(Bus bus) {
    int nextLandmarkIdx = bus.direction == 1 ? bus.currentSegmentIndex + 1 : bus.currentSegmentIndex;
    nextLandmarkIdx = nextLandmarkIdx.clamp(0, _landmarkNames.length - 1);
    
    // Estimate remaining time (seconds)
    double remainingProgress = bus.direction == 1 ? (1.0 - bus.progress) : bus.progress;
    int seconds = (remainingProgress * 30).round(); 
    if (seconds <= 0) seconds = 5; // fallback min ETA

    return '$seconds mins to ${_landmarkNames[nextLandmarkIdx]}';
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF0F172A),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        size: 20,
                        color: Color(0xFF6366F1),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'BusBin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                fontSize: 22,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[500],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(
              icon: Icon(Icons.map_rounded),
              text: 'Passenger View',
            ),
            Tab(
              icon: Icon(Icons.dashboard_rounded),
              text: 'Owner Dashboard',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // keep map responsive to gestures
        children: [
          // Tab 1: Passenger View
          _buildPassengerView(),

          // Tab 2: Owner Dashboard
          _buildOwnerDashboard(),
        ],
      ),
    );
  }

  /// Passenger View: Map and Info Overlay
  Widget _buildPassengerView() {
    return Stack(
      children: [
        // OpenStreetMap integration using flutter_map
        FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(27.7425, 85.3400), // Centered along the route
            initialZoom: 13.0,
            minZoom: 11.0,
            maxZoom: 17.0,
          ),
          children: [
            // Standard OSM tiles (free, no API key required)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.busbin.app',
            ),
            
            // Route Line
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: const Color(0xFF6366F1).withOpacity(0.8),
                  strokeWidth: 5.5,
                  isDotted: false,
                  borderColor: const Color(0xFF4338CA),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),

            // Bus Markers
            MarkerLayer(
              markers: _buses.map((bus) {
                final bool isSelected = _selectedBus?.id == bus.id;
                return Marker(
                  point: bus.currentPosition,
                  width: 55,
                  height: 55,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBus = bus;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing outer shadow for selected bus
                        if (isSelected)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bus.occupancyColor.withOpacity(0.35),
                            ),
                          ),
                        // Inner marker body
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: bus.occupancyColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        // Small label tag
                        Positioned(
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[700]!, width: 0.5),
                            ),
                            child: Text(
                              bus.id,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Bus Info Card Overlay at the bottom
        if (_selectedBus != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedBus!.occupancyColor.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedBus!.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF818CF8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedBus!.busNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Ratnapark ⇄ Budhanilkantha',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Occupancy Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedBus!.occupancyColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedBus!.occupancyColor,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          _selectedBus!.occupancyStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedBus!.occupancyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ETA info
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, color: Color(0xFF818CF8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _calculateETA(_selectedBus!),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Passenger detail
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Colors.grey, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${_selectedBus!.passengerCount} Pax',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Owner Dashboard View: Live metrics & table syncing
  Widget _buildOwnerDashboard() {
    final int totalPassengers = _buses.fold(0, (sum, bus) => sum + bus.passengerCount);
    final int totalRevenue = _buses.fold(0, (sum, bus) => sum + bus.revenue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fleet Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Overview Cards Grid
          Row(
            children: [
              // Total Revenue Card
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Revenue',
                  value: 'Rs. $totalRevenue',
                  subtitle: '25 NPR / passenger',
                  icon: Icons.monetization_on_rounded,
                  accentColor: const Color(0xFF10B981), // Emerald
                ),
              ),
              const SizedBox(width: 12),
              // Total Passengers Card
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Pax',
                  value: '$totalPassengers',
                  subtitle: 'Across 2 active buses',
                  icon: Icons.people_rounded,
                  accentColor: const Color(0xFF6366F1), // Indigo
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Live Bus Operations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Operations Table Container
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155), width: 1.0),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _buses.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
              itemBuilder: (context, index) {
                final bus = _buses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bus identity
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: bus.occupancyColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.directions_bus_rounded,
                              color: bus.occupancyColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus.id,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                bus.busNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Passenger Stats & Color Dot
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${bus.passengerCount} Pax',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bus.occupancyColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            bus.occupancyStatus,
                            style: TextStyle(
                              fontSize: 11,
                              color: bus.occupancyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // Estimated Revenue
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs. ${bus.revenue}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const Text(
                            'Revenue',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Simulation indicator card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Simulation Engine Active: Live metrics sync\'d across views.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Metric Card UI Helper
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
              Icon(icon, color: accentColor, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
