import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/office_model.dart';
import '../services/office_finder_service.dart';

class OfficeFinderScreen extends StatefulWidget {
  final String? initialOfficeId;

  const OfficeFinderScreen({
    super.key,
    this.initialOfficeId,
  });

  @override
  State<OfficeFinderScreen> createState() => _OfficeFinderScreenState();
}

class _OfficeFinderScreenState extends State<OfficeFinderScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  static const List<Office> _offices = [
    Office(
      id: '1',
      name: 'CNSS Tunis Centre',
      type: 'CNSS',
      lat: 36.8080,
      lng: 10.1830,
      address: 'Avenue de la Liberte, Tunis',
      description: 'Main branch with dedicated ramp access and street-level entry.',
      isAccessible: true,
      hasHandicapParking: true,
      hasRamp: true,
      hasElevator: true,
      openingHours: '08:00 - 16:30',
      rating: 4.8,
    ),
    Office(
      id: '2',
      name: 'CNAM Belvedere',
      type: 'CNAM',
      lat: 36.8120,
      lng: 10.1750,
      address: 'Place Pasteur, Belvedere',
      description: 'Accessible reception with lift support, but no dedicated parking bay.',
      isAccessible: true,
      hasHandicapParking: false,
      hasRamp: true,
      hasElevator: true,
      openingHours: '08:00 - 17:00',
      rating: 4.4,
    ),
    Office(
      id: '3',
      name: 'Municipalite de Tunis',
      type: 'Municipality',
      lat: 36.7990,
      lng: 10.1710,
      address: 'La Kasbah, Tunis',
      description: 'Historic building with partial access and no disabled parking.',
      isAccessible: false,
      hasHandicapParking: false,
      hasRamp: false,
      hasElevator: false,
      openingHours: '08:00 - 14:00',
      rating: 3.9,
    ),
  ];

  Office? _selectedOffice;
  List<LatLng> _currentRoute = const [];
  bool _showAccessibilityOnly = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialOfficeId != null) {
      final initial = _offices.where((office) => office.id == widget.initialOfficeId);
      if (initial.isNotEmpty) {
        _selectedOffice = initial.first;
        _currentRoute = OfficeFinderService.buildAccessibleRoute(initial.first);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectOffice(Office office) {
    setState(() {
      _selectedOffice = office;
      _currentRoute = OfficeFinderService.buildAccessibleRoute(office);
    });
    _mapController.move(office.position, 15.6);
  }

  @override
  Widget build(BuildContext context) {
    final displayedOffices = OfficeFinderService.sortOffices(
      _offices,
      accessibilityOnly: _showAccessibilityOnly,
      query: _searchQuery,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: OfficeFinderService.userLocation,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              if (_currentRoute.isNotEmpty)
                PolylineLayer(
                  key: const Key('office_route_polyline'),
                  polylines: [
                    Polyline(
                      points: _currentRoute,
                      color: const Color(0xFF8CF1D0),
                      borderColor: const Color(0xFF1D9E75),
                      borderStrokeWidth: 2,
                      strokeWidth: 6,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: OfficeFinderService.userLocation,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_pin_circle, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  ...displayedOffices.map(
                    (office) => Marker(
                      point: office.position,
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () => _selectOffice(office),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedOffice?.id == office.id
                                ? const Color(0xFFE8FFF7)
                                : Colors.white.withOpacity(0.16),
                            border: Border.all(
                              color: office.isAccessible
                                  ? const Color(0xFF8CF1D0)
                                  : const Color(0xFFFFB4A2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_selectedOffice?.id == office.id
                                        ? const Color(0xFF8CF1D0)
                                        : Colors.black)
                                    .withOpacity(0.28),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            office.hasRamp ? Icons.accessible_forward : Icons.location_city,
                            color: _selectedOffice?.id == office.id
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _glass(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maak Premium Finder',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Accessibility-first office routing',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8CF1D0).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.assured_workload, color: Color(0xFF8CF1D0)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glass(
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Search accessible offices...',
                          hintStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Accessibility first'),
                            selected: _showAccessibilityOnly,
                            onSelected: (value) =>
                                setState(() => _showAccessibilityOnly = value),
                            backgroundColor: Colors.white.withOpacity(0.06),
                            selectedColor: const Color(0xFF8CF1D0).withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.white),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SizedBox(
              height: 335,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayedOffices.length,
                itemBuilder: (context, index) {
                  return _buildOfficeCard(displayedOffices[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeCard(Office office) {
    final isSelected = _selectedOffice?.id == office.id;
    final distance = OfficeFinderService.distanceInKm(office);
    final arReady = OfficeFinderService.shouldSuggestArNavigation(office);

    return GestureDetector(
      onTap: () => _selectOffice(office),
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 16),
        child: _glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: office.isAccessible
                            ? const [Color(0xFF8CF1D0), Color(0xFF38BDF8)]
                            : const [Color(0xFFFFB4A2), Color(0xFFF97316)],
                      ),
                    ),
                    child: Icon(
                      office.hasRamp ? Icons.accessible_forward : Icons.warning_amber,
                      color: const Color(0xFF05212E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          office.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          office.address,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.route : Icons.chevron_right,
                    color: const Color(0xFF8CF1D0),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                office.description,
                style: const TextStyle(color: Colors.white70, height: 1.25, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _badge(
                    Icons.accessible_forward,
                    office.isAccessible ? 'Accessible' : 'Limited',
                    office.isAccessible,
                  ),
                  _badge(
                    Icons.local_parking,
                    office.hasHandicapParking ? 'Parking' : 'No Parking',
                    office.hasHandicapParking,
                  ),
                  _badge(
                    Icons.stairs,
                    office.hasRamp ? 'Ramp' : 'No Ramp',
                    office.hasRamp,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route suitability',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (office.accessibilityScore / 10).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          color: const Color(0xFF8CF1D0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: Color(0xFF8CF1D0),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: FilledButton(
                        key: Key('navigate_button_${office.id}'),
                        onPressed: () => _selectOffice(office),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8CF1D0),
                          foregroundColor: const Color(0xFF05212E),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Navigate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  if (arReady) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamed(context, '/cv'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Launch AR', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!office.hasHandicapParking) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB4A2).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFB4A2).withOpacity(0.24)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Color(0xFFFFB4A2), size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Warning: no dedicated disabled parking.',
                          style: TextStyle(color: Color(0xFFFFD6CC), fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF8CF1D0).withOpacity(0.12)
            : const Color(0xFFFFB4A2).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF8CF1D0) : const Color(0xFFFFB4A2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: active ? const Color(0xFF8CF1D0) : const Color(0xFFFFB4A2)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF8CF1D0) : const Color(0xFFFFD6CC),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glass({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}
