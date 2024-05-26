import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Itinerary (Public Transport)',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController useridController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController birthdateController = TextEditingController();
  TextEditingController mobilenumberController = TextEditingController();


  PolylinePoints polylinePoints = PolylinePoints();

  Map endmode = {"No return to start point":1, "Return to start point":2, "User specified end point":3};

  List jsonlist = [];
  List coords = [];
  List legs = [];
  List pois = [];
  List<Marker> markersdata = [];
  List<TaggedPolyline> polydata = [];
  int selectedidx = -1;

  Future<void> sendPostRequest() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:7687/adduser'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Connection': 'Keep-Alive'
      },
      // body: jsonEncode({
      //   'topn': titleController.text,
      //   'vehiclemode': bodyController.text,
      //   'mode': endmode[endmodeController.text],
      // }),
      body: jsonEncode({
        'userid': useridController.text,
        'name': nameController.text,
        'age': ageController.text,
        'gender': genderController.text,
        'password': passwordController.text,
        'email': emailController.text,
        'birthdate': birthdateController.text,
        'mobilenumber': mobilenumberController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Post created successfully!"),
      ));
      setState(() {
        jsonlist = json.decode(response.body);
      });
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to create post!"),
      ));
    }
  }

  createItineraries() {
      markersdata = [];
      polydata = [];

      coords = jsonlist[selectedidx]["Coords"];

      for (int j = 0; j < jsonlist[selectedidx]["Routes"].length; j++) {
        legs = jsonlist[selectedidx]["Routes"][j]["plan"]["itineraries"][0]["legs"];
        for (int i = 0; i < legs.length; i++) {
          String travelmode = legs[i]["mode"];
          String? mrtlinename = legs[i]["routeLongName"];
          String? busno = legs[i]["routeShortName"];
          String fromname = legs[i]["from"]["name"];
          String toname = legs[i]["to"]["name"];
          String encodedpoly = legs[i]["legGeometry"]["points"];
          List decodedpoly = polylinePoints.decodePolyline(encodedpoly);
          List<LatLng> polypoints = decodedpoly
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          if (travelmode == "SUBWAY") {
            polydata.add(TaggedPolyline(
              tag: "Take the $mrtlinename from $fromname to $toname.",
              points: polypoints,
              strokeWidth: 5.0,
              color: Colors.purple,
            ));
          } else if (travelmode == "BUS") {
            polydata.add(TaggedPolyline(
              tag: "Take Bus $busno from $fromname to $toname.",
              points: polypoints,
              strokeWidth: 5.0,
              color: Colors.black,
            ));
          } else {
            polydata.add(TaggedPolyline(
              tag: "Walk from $fromname to $toname.",
              points: polypoints,
              strokeWidth: 5.0,
              color: Colors.grey.shade700,
              isDotted: true,
              borderStrokeWidth: 2.0,
              borderColor: Colors.white,
            ));
          }
        }
      }

      for (int i = 0; i < coords.length; i++) {
        if (i == 0) {
          pois.add("Starting Point");
        } else {
          pois.add(jsonlist[selectedidx]["Itinerary"][i]);
        }

        markersdata.add(
          NamedMarker(
            name: pois[i],
            lat: coords[i][0],
            lng: coords[i][1],
          ),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Map Itinerary (Public Transport)'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: useridController,
                decoration: InputDecoration(hintText: "topn: 1,2"),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: "vehiclemode: 4"),
              ),
              TextField(
                controller: ageController,
                decoration: InputDecoration(hintText: "mode: 1,2,3"),
              ),
              TextField(
                controller: genderController,
                decoration: InputDecoration(hintText: "mode: 1,2,3"),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(hintText: "mode: 1,2,3"),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(hintText: "mode: 1,2,3"),
              ),
              TextField(
                controller: birthdateController,
                decoration: InputDecoration(hintText: "mode: 1,2,3"),
              ),
              TextField(
                controller: mobilenumberController,
                decoration: InputDecoration(hintText: "mode: 1,2,3"),
              ),
              // DropdownMenu(
              //   dropdownMenuEntries: endmode.keys.map<DropdownMenuEntry>((value) {
              //   return DropdownMenuEntry(value: value, label: value);
              // }).toList(),
              //   controller: endmodeController,
              //   initialSelection: endmode.keys.first,
              // ),
              ElevatedButton(
                onPressed: sendPostRequest,
                child: Text("Create Post"),
              ),
              ElevatedButton(
                child: Text("Map"),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MapPage(
                              coords: coords,
                              polydata: polydata,
                              markersdata: markersdata)));
                },
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: jsonlist.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    tileColor: Colors.blueGrey,
                    selectedTileColor: Colors.blue,
                    title: Text ("Itinerary ${index+1}"),
                    onTap: () {
                      setState(() {
                        selectedidx = index;
                      });
                      createItineraries();
                    },
                    selected: selectedidx == index
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MapPage extends StatelessWidget {
  final List coords;
  final List<TaggedPolyline> polydata;
  final List<Marker> markersdata;
  MapPage(
      {Key? key,
      required this.coords,
      required this.polydata,
      required this.markersdata})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                minZoom: 11,
                maxZoom: 19,
                initialCenter: LatLng(coords[0][0], coords[0][1]),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://www.onemap.gov.sg/maps/tiles/Default/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.app",
                ),
                TappablePolylineLayer(
                  polylineCulling: true,
                  polylines: polydata,
                  onTap: (polylines, tapPosition) {
                    showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                              child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                  title: Text(polylines
                                      .map((polyline) => polyline.tag)
                                      .toString()))
                            ],
                          ));
                        });
                  },
                ),
                PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    markers: markersdata,
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (BuildContext context, Marker marker) {
                        if (marker is NamedMarker) {
                          return Card(child: Text(marker.name, style: TextStyle(fontSize: 20.0),));
                        }
                        return const Card(
                            child: Text("This marker has no name"));
                      },
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
}

class NamedMarker extends Marker {
  NamedMarker({required this.name, required this.lat, required this.lng})
      : super(
          alignment: Alignment.topCenter,
          rotate: true,
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        );

  final String name;
  final double lat;
  final double lng;
}
