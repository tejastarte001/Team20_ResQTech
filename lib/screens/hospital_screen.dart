import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  @override
  _NearbyHospitalsScreenState createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  LatLng? _currentLocation;
  Set<Marker> _hospitalMarkers = {};
  List<Map<String, dynamic>> _hospitalList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedHospitalIndex = -1;
  bool _showMapFullscreen = false;
  late GoogleMapController _mapController;

  final String _backendUrl =
      'https://us-central1-emergency-alert-system-e0a91.cloudfunctions.net/getNearbyHospitals';

  @override
  void initState() {
    super.initState();
    _fetchLocationAndHospitals();
  }

  Future<void> _fetchLocationAndHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hospitalList.clear();
      _hospitalMarkers.clear();
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception('Location permission not granted');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      await _fetchNearbyHospitals(position.latitude, position.longitude);
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _errorMessage = 'Failed to get location or load hospitals';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyHospitals(double lat, double lng) async {
    final url = '$_backendUrl?lat=$lat&lng=$lng';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final List results = data['results'];

        List<Map<String, dynamic>> hospitals = results
            .map<Map<String, dynamic>>((place) {
              final double hospitalLat = place['lat'];
              final double hospitalLng = place['lng'];
              final double distanceInMeters = Geolocator.distanceBetween(
                lat,
                lng,
                hospitalLat,
                hospitalLng,
              );

              return {
                'name': place['name'],
                'lat': hospitalLat,
                'lng': hospitalLng,
                'address': place['address'] ?? 'Address not available',
                'phone': place['phone'] ?? 'Not available',
                'distance': distanceInMeters,
                'rating': (place['rating'] ?? 0.0).toDouble(),
                'open_now':
                    place['open_now'] ??
                    true, // Default to open if status not available
              };
            })
            .toList();

        hospitals.sort((a, b) => a['distance'].compareTo(b['distance']));

        Set<Marker> markers = {};
        for (int i = 0; i < hospitals.length; i++) {
          final hospital = hospitals[i];
          markers.add(
            Marker(
              markerId: MarkerId('hospital_$i'),
              position: LatLng(hospital['lat'], hospital['lng']),
              infoWindow: InfoWindow(
                title: hospital['name'],
                snippet: hospital['address'],
              ),
              icon: await _createCustomMarkerIcon(i),
              onTap: () {
                setState(() {
                  _selectedHospitalIndex = i;
                });
                _scrollToHospital(i);
              },
            ),
          );
        }

        setState(() {
          _hospitalMarkers = markers;
          _hospitalList = hospitals;
        });
      } else {
        setState(() {
          _errorMessage = 'No hospitals found nearby';
        });
      }
    } catch (e) {
      print('Fetch error: $e');
      setState(() {
        _errorMessage = 'Failed to load hospital data';
      });
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon(int index) async {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: (index + 1).toString(),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final paint = Paint()
      ..color = _selectedHospitalIndex == index
          ? Colors.deepPurple
          : Colors.redAccent;

    canvas.drawCircle(
      Offset(textPainter.width / 2 + 4, textPainter.height / 2 + 4),
      textPainter.width / 2 + 8,
      paint,
    );

    textPainter.paint(canvas, Offset(4, 4));

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
      textPainter.width.toInt() + 16,
      textPainter.height.toInt() + 16,
    );
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _scrollToHospital(int index) {
    final scrollController = PrimaryScrollController.of(context);
    if (scrollController.hasClients) {
      scrollController.animateTo(
        index * 220.0, // Adjusted height of each card
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch maps'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open dialer: $e')));
    }
  }

  Widget _buildDistanceIndicator(double distance) {
    final double distanceKm = distance / 1000;
    Color color;
    IconData icon;

    if (distanceKm < 1) {
      color = Colors.green;
      icon = Icons.directions_walk;
    } else if (distanceKm < 3) {
      color = Colors.orange;
      icon = Icons.directions_bike;
    } else {
      color = Colors.red;
      icon = Icons.directions_car;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingIndicator(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 16, color: Colors.amber),
        SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> hospital, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: _selectedHospitalIndex == index
            ? Border.all(color: Colors.deepPurple, width: 2)
            : null,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedHospitalIndex = index;
            });
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Center(
                          child: Icon(
                            Icons.local_hospital, // Material hospital icon
                            size: 24,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              if (hospital['rating'] != 0)
                                _buildRatingIndicator(hospital['rating']),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: hospital['open_now']
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hospital['open_now'] ? 'OPEN' : 'CLOSED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: hospital['open_now']
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildDistanceIndicator(hospital['distance']),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hospital['address'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      hospital['phone'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.directions_outlined, size: 18),
                        label: Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[800],
                          side: BorderSide(color: Colors.blue[200]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () =>
                            _openMaps(hospital['lat'], hospital['lng']),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.call_outlined, size: 18),
                        label: Text(
                          'Call',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _makePhoneCall(hospital['phone']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
      child: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 14,
            ),
            markers: _hospitalMarkers.union({
              Marker(
                markerId: MarkerId('currentLocation'),
                position: _currentLocation!,
                infoWindow: InfoWindow(title: 'Your Location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
            }),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(top: 60, bottom: 40),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (LatLng position) {
              setState(() {
                _selectedHospitalIndex = -1;
              });
            },
          ),
          // Positioned(
          //   top: 16,
          //   right: 16,
          //   child: FloatingActionButton(
          //     mini: true,
          //     backgroundColor: Colors.white,
          //     onPressed: () {
          //       _mapController.animateCamera(
          //         CameraUpdate.newLatLng(_currentLocation!),
          //       );
          //     },
          //     child: Icon(Icons.my_location, color: Colors.grey[800]),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.4),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 60, height: 24, color: Colors.white),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 120, height: 40, color: Colors.white),
                    Container(width: 120, height: 40, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMap(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off, // Material location error icon
                  size: 150,
                  color: Colors.red, // Optional: add color if needed
                ),
                SizedBox(height: 24),
                Text(
                  _errorMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetchLocationAndHospitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Try Again'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildMap(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_services_outlined, // Alternative medical icon
                  size: 150,
                  color: Colors.grey, // Optional: add color if needed
                ),
                SizedBox(height: 24),
                Text(
                  'No hospitals found nearby',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try moving to a different location',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetchLocationAndHospitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 20),
                      SizedBox(width: 8),
                      Text('Search Again'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _currentLocation == null) {
      return _buildLoadingShimmer();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_hospitalList.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildMap(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchLocationAndHospitals,
            displacement: 40,
            edgeOffset: 20,
            color: Colors.redAccent,
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: _hospitalList.length,
              itemBuilder: (context, index) {
                return _buildHospitalCard(_hospitalList[index], index);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Hospitals'),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchLocationAndHospitals,
          ),
        ],
      ),
      body: _currentLocation == null && _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
}
