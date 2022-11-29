import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_maps/secrets.dart'; // Stores the Google Maps API Key
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_maps/directions.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:location/location.dart' as location;

class MapView extends StatefulWidget {
  static const String id = 'map_view';
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User user;
  final CameraPosition _initialLocation =
      const CameraPosition(target: LatLng(0.0, 0.0));
  GoogleMapController? mapController;
  int b = 0;
  late location.LocationData _currentPosition;
  String _currentAddress = '';

  List<List<PointLatLng>> decodedPoints = [];

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  String? _placeDistance;

  Set<Marker> markers = {};
  LocationService locationService = LocationService();
  final player = AudioPlayer();
  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  // int _polylineIdCounter = 1;
  List<LatLng> polylineCoordinates = [];
  // Queue<Set<double>> ans = Queue();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  location.LocationData? currentLocation;
  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
  }) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    location.Location()
        .changeSettings(accuracy: location.LocationAccuracy.navigation);
    await location.Location().getLocation().then((position) async {
      _currentPosition = position;

      setState(() {
        print('CURRENT POS: $_currentPosition');
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude!, position.longitude!),
              zoom: 18.0,
            ),
          ),
        );
      });

      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude!, _currentPosition.longitude!);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      // Retrieving placemarks from addresses
      List<Location> startPlacemark = await locationFromAddress(_startAddress);
      List<Location> destinationPlacemark =
          await locationFromAddress(_destinationAddress);

      // Use the retrieved coordinates of the current position,
      // instead of the address if the start position is user's
      // current position, as it results in better accuracy.
      double startLatitude = _currentPosition.latitude!;

      double startLongitude = _currentPosition.longitude!;

      double destinationLatitude = destinationPlacemark[0].latitude;
      double destinationLongitude = destinationPlacemark[0].longitude;

      String startCoordinatesString = '($startLatitude, $startLongitude)';
      String destinationCoordinatesString =
          '($destinationLatitude, $destinationLongitude)';

      // Start Location Marker
      Marker startMarker = Marker(
        markerId: MarkerId(startCoordinatesString),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(
          title: 'Start $startCoordinatesString',
          snippet: _startAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Destination Location Marker
      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: 'Destination $destinationCoordinatesString',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Adding the markers to the list
      markers.add(startMarker);
      markers.add(destinationMarker);

      print(
        'START COORDINATES: ($startLatitude, $startLongitude)',
      );
      print(
        'DESTINATION COORDINATES: ($destinationLatitude, $destinationLongitude)',
      );

      // Calculating to check that the position relative
      // to the frame, and pan & zoom the camera accordingly.
      double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      // Accommodate the two locations within the
      // camera view of the map
      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );

      // Calculating the distance between the start and the end positions
      // with a straight path, without considering any route
      // double distanceInMeters = await Geolocator.bearingBetween(
      //   startLatitude,
      //   startLongitude,
      //   destinationLatitude,
      //   destinationLongitude,
      // );
      double totalDistance = 0.0;
      decodedPoints = await locationService.getDirections(startLatitude,
          startLongitude, destinationLatitude, destinationLongitude);

      // setState(() {
      //   polylineCoordinates.clear();
      //   polylines.clear();
      // });

      // print(locationService.s);
      // int z = 1;
      for (int i = 0; i < decodedPoints.length; i++) {
        for (var point in decodedPoints.elementAt(i)) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        _setOfPolylinesPoints(polylineCoordinates);
        // z++;
        // locationService.decodedPoints.removeFirst();
        //
      }
      // await _createPolylines(startLatitude, startLongitude, destinationLatitude,
      //     destinationLongitude);

      // Calculating the total distance by adding the distance
      // between small segments
      // for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      //   totalDistance += _coordinateDistance(
      //     polylineCoordinates[i].latitude,
      //     polylineCoordinates[i].longitude,
      //     polylineCoordinates[i + 1].latitude,
      //     polylineCoordinates[i + 1].longitude,
      //   );
      // }
      setState(() {
        _placeDistance = locationService.distance;
        print('DISTANCE: $_placeDistance ');
      });

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  // Formula for calculating distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Secrets.apikey, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
    );
    print(result);
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    _setOfPolylinesPoints(polylineCoordinates);
  }
  //

  _setOfPolylinesPoints(List<LatLng> myPolylineCoordinates) {
    PolylineId id = const PolylineId('poly');
    // final String polylineIdVal = 'marker_id_$_polylineIdCounter';
    // _polylineIdCounter++;
    // final PolylineId polylineId = PolylineId(polylineIdVal);

    Polyline polyline = Polyline(
      polylineId: id,
      visible: true,
      color: Colors.red,
      points: myPolylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  void currrentUser() {
    try {
      user = _auth.currentUser!;
      print(user.email);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    currrentUser();
    _getCurrentLocation();
    location.Location().changeSettings(
        accuracy: location.LocationAccuracy.low,
        interval: 2000,
        distanceFilter: 2);
    location.Location().onLocationChanged.listen((newLoc) {
      _currentPosition = newLoc;
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(newLoc.latitude!, newLoc.longitude!),
            zoom: 18.0,
          ),
        ),
      );
      // setState(() {});
      if (locationService.s.isNotEmpty) {
        print(locationService.s);
        // for (var element in locationService.s) {
        //   print(element);
        // }
        // prin
        //     "${locationService.s.first.elementAt(0)}hello my name is nimit");
        if ((_coordinateDistance(
                    newLoc.latitude!,
                    newLoc.longitude!,
                    locationService.s.first.elementAt(0),
                    locationService.s.first.elementAt(1))) *
                1000 <
            10) {
          //   // polylineCoordinates.remove(
          //   //   LatLng(
          //   //     locationService.s.first.elementAt(0),
          //   //     locationService.s.first.elementAt(1),
          //   //   ),
          //   // );
          //   // _setOfPolylinesPoints(polylineCoordinates);
          locationService.s.removeFirst();
          if (locationService.decoded.isNotEmpty) {
            for (var point in locationService.decoded.first) {
              polylineCoordinates
                  .remove(LatLng(point.latitude, point.longitude));
            }
            locationService.decoded.removeFirst();
          }

          setState(() {
            _setOfPolylinesPoints(polylineCoordinates);
            player.play(AssetSource('horn.wav'));
          });
        }
      }

      // polylineCoordinates.clear();
      // polylines.clear();
      // await _createPolylines(
      //     newLoc.latitude!,
      //     newLoc.longitude!,
      //     destinationPlacemark[0].latitude,
      //     destinationPlacemark[0].longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            // Map View
            GoogleMap(
              markers: Set<Marker>.from(markers),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            // Show zoom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController?.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController?.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Show the place input fields & button for
            // showing the route
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Places',
                            style: TextStyle(fontSize: 20.0),
                          ),
                          const SizedBox(height: 10),
                          _textField(
                              label: 'Start',
                              hint: 'Choose starting point',
                              prefixIcon: const Icon(Icons.looks_one),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: _getAddress,
                              ),
                              controller: startAddressController,
                              focusNode: startAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _startAddress = value;
                                });
                              }),
                          const SizedBox(height: 10),
                          _textField(
                              label: 'Destination',
                              hint: 'Choose destination',
                              prefixIcon: const Icon(Icons.looks_two),
                              controller: destinationAddressController,
                              focusNode: desrinationAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _destinationAddress = value;
                                });
                              }),
                          const SizedBox(height: 10),
                          Visibility(
                            visible: _placeDistance == null ? false : true,
                            child: Text(
                              'DISTANCE: $_placeDistance',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          ElevatedButton(
                            onPressed: (_startAddress != '' &&
                                    _destinationAddress != '')
                                ? () async {
                                    startAddressFocusNode.unfocus();
                                    desrinationAddressFocusNode.unfocus();
                                    setState(() {
                                      if (markers.isNotEmpty) markers.clear();
                                      if (polylines.isNotEmpty) {
                                        polylines.clear();
                                      }
                                      if (decodedPoints.isNotEmpty) {
                                        decodedPoints.clear();
                                      }
                                      if (polylineCoordinates.isNotEmpty) {
                                        polylineCoordinates.clear();
                                      }
                                      _placeDistance = null;
                                    });

                                    _calculateDistance().then((isCalculated) {
                                      if (isCalculated) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Distance Calculated Sucessfully'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Error Calculating Distance'),
                                          ),
                                        );
                                      }
                                    });
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Show Route'.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Show current location button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ClipOval(
                        child: Material(
                          color: Colors.orange.shade100, // button color
                          child: InkWell(
                            splashColor: Colors.orange, // inkwell color
                            child: const SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(Icons.logout),
                            ),
                            onTap: () async {
                              await _auth.signOut();
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                        width: 10,
                      ),
                      ClipOval(
                        child: Material(
                          color: Colors.orange.shade100, // button color
                          child: InkWell(
                            splashColor: Colors.orange, // inkwell color
                            child: const SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(Icons.my_location),
                            ),
                            onTap: () {
                              mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      _currentPosition.latitude!,
                                      _currentPosition.longitude!,
                                    ),
                                    zoom: 18.0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    startAddressController.dispose();
    destinationAddressController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
