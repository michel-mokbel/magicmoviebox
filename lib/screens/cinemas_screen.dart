import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/ads_service.dart';

class CinemasScreen extends StatefulWidget {
  const CinemasScreen({super.key});

  @override
  State<CinemasScreen> createState() => _CinemasScreenState();
}

class _CinemasScreenState extends State<CinemasScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyCinemas = [];
  bool _isLoading = true;
  String? _error;
  Set<Marker> _markers = {};
  final String _apiKey = 'AIzaSyCsiw4EUdPsStONc7B3rLOh9gwxdP6IE7U';
  bool _mapInitialized = false;
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _error = 'Location services are disabled. Please enable location services in your device settings.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _error = 'Location permissions are denied. Please enable them in your device settings.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _error = 'Location permissions are permanently denied. Please enable them in your device settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _error = null;
        });
        await _searchNearbyCinemas();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error getting location: $e';
        });
      }
    }
  }

  Future<void> _searchNearbyCinemas() async {
    if (_currentPosition == null) return;

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&radius=10000'
          '&type=cinema'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        if (mounted) {
          setState(() {
            _nearbyCinemas = List<Map<String, dynamic>>.from(data['results']);
            _markers = _nearbyCinemas.map((cinema) {
              final location = cinema['geometry']['location'];
              return Marker(
                markerId: MarkerId(cinema['place_id']),
                position: LatLng(location['lat'], location['lng']),
                infoWindow: InfoWindow(
                  title: cinema['name'],
                  snippet: cinema['vicinity'],
                ),
              );
            }).toSet();
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        throw Exception(data['error_message'] ?? 'Failed to fetch nearby cinemas');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error fetching nearby cinemas: $e';
        });
      }
    }
  }

  Future<void> _launchMaps(double lat, double lng, String placeId) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$placeId';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    try {
      _mapController = controller;
      await controller.setMapStyle('''
        [
          {
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#212121"
              }
            ]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#757575"
              }
            ]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [
              {
                "color": "#212121"
              }
            ]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#000000"
              }
            ]
          }
        ]
      ''');
      setState(() {
        _mapInitialized = true;
      });
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _error = 'Error initializing map: $e';
      });
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeLocation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 13,
        ),
        markers: _markers,
        onMapCreated: _onMapCreated,
        myLocationEnabled: _mapInitialized,
        myLocationButtonEnabled: _mapInitialized,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Nearby Cinemas',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner ad at the top
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: _adsService.showBannerAd(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : _error != null
                    ? _buildErrorWidget(_error!)
                    : _currentPosition == null
                        ? _buildErrorWidget('Location not available')
                        : Column(
                            children: [
                              _buildMap(),
                              Expanded(
                                child: _nearbyCinemas.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No cinemas found nearby',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _nearbyCinemas.length,
                                        itemBuilder: (context, index) {
                                          final cinema = _nearbyCinemas[index];
                                          final location = cinema['geometry']['location'];
                                          
                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            color: Colors.grey[900],
                                            child: ListTile(
                                              leading: cinema['photos'] != null && cinema['photos'].isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: 'https://maps.googleapis.com/maps/api/place/photo'
                                                          '?maxwidth=100'
                                                          '&photo_reference=${cinema['photos'][0]['photo_reference']}'
                                                          '&key=$_apiKey',
                                                      height: 40,
                                                      width: 40,
                                                      placeholder: (context, url) => const Icon(
                                                        Icons.movie,
                                                        size: 40,
                                                        color: Colors.red,
                                                      ),
                                                      errorWidget: (context, url, error) => const Icon(
                                                        Icons.movie,
                                                        size: 40,
                                                        color: Colors.red,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.movie,
                                                      size: 40,
                                                      color: Colors.red,
                                                    ),
                                              title: Text(
                                                cinema['name'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cinema['vicinity'] ?? 'Unknown location',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Rating: ${cinema['rating']?.toString() ?? 'N/A'}',
                                                        style: const TextStyle(
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                      if (cinema['opening_hours'] != null)
                                                        Text(
                                                          cinema['opening_hours']['open_now'] ? 'Open Now' : 'Closed',
                                                          style: TextStyle(
                                                            color: cinema['opening_hours']['open_now'] ? Colors.green : Colors.red,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.directions, color: Colors.red),
                                                onPressed: () => _launchMaps(
                                                  location['lat'],
                                                  location['lng'],
                                                  cinema['place_id'],
                                                ),
                                              ),
                                              onTap: () async {
                                                final lat = location['lat'];
                                                final lng = location['lng'];
                                                await _openInGoogleMaps(lat, lng, cinema['name']);
                                              },
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps(double lat, double lng, String name) async {
    // Show interstitial ad
    await _adsService.showInterstitialAd();
    
    // Open in Google Maps
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=${Uri.encodeComponent(name)}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
} 