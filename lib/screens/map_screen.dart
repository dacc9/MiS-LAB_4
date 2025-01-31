import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/exam_event_model.dart';
import '../services/database_service.dart';

class MapScreen extends StatefulWidget {
  final ExamEvent? selectedEvent;
  const MapScreen({Key? key, this.selectedEvent}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<ExamEvent> _events = [];
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  double? _distance;
  int? _duration;
  List<String> _instructions = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _getCurrentLocation();
  }

  Future<void> _loadEvents() async {
    final events = await _databaseService.getEvents();
    setState(() {
      _events = events;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      if (widget.selectedEvent != null) {
        _getRoute();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getRoute() async {
    if (_currentLocation == null || widget.selectedEvent == null) return;

    setState(() {
      _isLoadingRoute = true;
      _routePoints = [];
      _instructions = [];
    });

    try {
      final coordinates = '${_currentLocation!.longitude},${_currentLocation!.latitude};${widget.selectedEvent!.longitude},${widget.selectedEvent!.latitude}';
      final url = 'https://routing.openstreetmap.de/routed-car/route/v1/driving/$coordinates?overview=full&geometries=geojson&steps=true';

      print('Requesting route: $url'); // Debug print

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          // Convert coordinates to LatLng points
          final points = coordinates.map((coord) =>
              LatLng(coord[1] as double, coord[0] as double)
          ).toList();

          // Get route steps
          List<String> stepInstructions = [];
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final steps = route['legs'][0]['steps'] as List;
            stepInstructions = steps.map<String>((step) {
              final instruction = step['maneuver']['instruction'];
              final distance = (step['distance'] as num).round();
              return '$instruction ($distance m)';
            }).toList();
          }

          setState(() {
            _routePoints = points;
            _distance = route['distance'] / 1000; // Convert to kilometers
            _duration = (route['duration'] / 60).round(); // Convert to minutes
            _instructions = stepInstructions;
            _isLoadingRoute = false;
          });
        }
      } else {
        print('Error response: ${response.body}');
        setState(() {
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      print('Error getting route: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мапа на испити'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _currentLocation ?? LatLng(41.9981, 21.4254),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30.0,
                        ),
                      ),
                    ..._events.map(
                          (event) => Marker(
                        point: LatLng(event.latitude, event.longitude),
                        child: Icon(
                          Icons.location_on,
                          color: widget.selectedEvent?.id == event.id
                              ? Colors.red
                              : Colors.green,
                          size: 30.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoadingRoute)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (widget.selectedEvent != null && _distance != null)
            Container(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Испит: ${widget.selectedEvent!.title}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text('Растојание: ${_distance!.toStringAsFixed(2)} km'),
                      if (_duration != null)
                        Text('Време до локација: $_duration минути'),
                      Text(
                        'Време на испит: ${widget.selectedEvent!.dateTime.hour}:${widget.selectedEvent!.dateTime.minute.toString().padLeft(2, '0')}',
                      ),
                      if (_instructions.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          'Насоки:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          height: 100,
                          child: ListView.builder(
                            itemCount: _instructions.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text('${index + 1}. ${_instructions[index]}'),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: Icon(Icons.my_location),
      ),
    );
  }
}