import 'dart:collection';
import 'dart:convert';
// import 'package:flutter/material.dart';
import 'package:flutter_maps/secrets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// void main() {
//   LocationService().getDirections('Aravali Vihar Colony, Ajmer, 305001, India',
//       'Maheshwari Public School, Ajmer');
// }

class LocationService {
  String distance = '';
  // Set<Polyline> polyline = {};
  // final List<LatLng> polylineCoordinates = [];
  Queue<Set<double>> s = Queue();

  Queue<List<PointLatLng>> decoded = Queue();
  var key = Secrets.apikey;
  Future<List<List<PointLatLng>>> getDirections(
    double sLat,
    double sLng,
    double dLat,
    double dLng,
  ) async {
    List<List<PointLatLng>> decodedPoints = [];
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?destination=$dLat,$dLng&origin=$sLat,$sLng&key=$key';
    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);
    // print(json);
    var noOfSteps = json['routes'][0]['legs'][0]['steps'].length;

    distance = json['routes'][0]['legs'][0]['distance']['text'];
    // print(distance);
    for (int i = 0; i < noOfSteps; i++) {
      // List<LatLng> polylineCoordinates = [];
      List<PointLatLng> polyLinePoints1 = PolylinePoints().decodePolyline(
          json['routes'][0]['legs'][0]['steps'][i]['polyline']['points']);
      decodedPoints.add(polyLinePoints1);
      decoded.addLast(polyLinePoints1);
      s.addLast({
        json['routes'][0]['legs'][0]['steps'][i]['end_location']['lat'],
        json['routes'][0]['legs'][0]['steps'][i]['end_location']['lng']
      });
    }
    return decodedPoints;
  }
}
