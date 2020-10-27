import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  Set<Marker> _mapMarkers = Set();
  Set<Polygon> _poligonos = Set();
  GoogleMapController _mapController;
  TextEditingController _inputController = TextEditingController();
  Position _currentPosition;
  Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );

  @override
  Widget build(BuildContext context) {
    String _value;
    _searchDirection() {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Search by address"),
              content: TextField(
                controller: _inputController,
                decoration: const InputDecoration(hintText: "type address..."),
              ),
              actions: <Widget>[
                FlatButton(
                    color: Colors.red,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Cancel")),
                FlatButton(
                    color: Colors.blue,
                    onPressed: () async {
                      List<Placemark> placemark = await Geolocator()
                          .placemarkFromAddress(_inputController.text);
                      _mapController.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(
                              placemark.first.position.latitude,
                              placemark.first.position.longitude,
                            ),
                            zoom: 15.0,
                          ),
                        ),
                      );
                      _inputController.clear();
                      Navigator.of(context).pop();
                    },
                    child: Text("Search")),
              ],
            );
          });
    }

    _drawPol() {
      setState(() {
        if (_poligonos.isEmpty) {
          List<LatLng> list = new List();
          _mapMarkers.forEach((marker) {
            if (marker.position.latitude != _currentPosition.latitude ||
                marker.position.longitude != marker.position.longitude) {
              list.add(marker.position);
            }
          });
          _poligonos.add(Polygon(
              polygonId: PolygonId("value"),
              points: list,
              strokeColor: Colors.purple,
              fillColor: Colors.purple));
        } else {
          _poligonos = Set();
        }
      });
    }

    _aboutPlacemark(Placemark p) {
      showModalBottomSheet(
          context: context,
          builder: (BuildContext bc) {
            return Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      title: new Text('Country'),
                      subtitle: Text(p.country),
                      onTap: () => {print(p.country)}),
                  new ListTile(
                    title: new Text('Locality'),
                    subtitle: Text(p.locality),
                    onTap: () => {print(p.locality)},
                  ),
                  new ListTile(
                    title: new Text('Street'),
                    subtitle: Text(p.thoroughfare),
                    onTap: () => {},
                  ),
                  new ListTile(
                    title: new Text('CP'),
                    subtitle: Text(p.postalCode),
                    onTap: () => {print(p.postalCode)},
                  ),
                  new ListTile(
                    title: new Text('Coordinates'),
                    subtitle: Text(
                        "${p.position.latitude.toString()}, ${p.position.longitude.toString()}"),
                    onTap: () => {},
                  )
                ],
              ),
            );
          });
    }

    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        if (result.error == null) {
          if (_currentPosition == null) _currentPosition = _defaultPosition;
          return Scaffold(
            appBar: AppBar(
              title: Text("Google maps"),
              actions: <Widget>[
                DropdownButton<String>(
                  items: [
                    DropdownMenuItem<String>(
                      child: FlatButton(
                        onPressed: () {
                          _getCurrentPosition();
                          Navigator.of(context).pop();
                        },
                        child: Text("Current position"),
                      ),
                      value: 'one',
                    ),
                    DropdownMenuItem<String>(
                      child: FlatButton(
                        onPressed: () {
                          _searchDirection();
                        },
                        child: Text("Type address"),
                      ),
                      value: 'two',
                    ),
                    DropdownMenuItem<String>(
                      child: FlatButton(
                        onPressed: () {
                          _drawPol();
                          Navigator.of(context).pop();
                        },
                        child: Text("Draw poligon"),
                      ),
                      value: 'three',
                    ),
                  ],
                  onChanged: (String value) {
                    setState(() {
                      _value = value;
                    });
                  },
                  hint: Text('Seleccione una opcion'),
                  value: _value,
                ),
              ],
            ),
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  markers: _mapMarkers,
                  onLongPress: _setMarker,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                  ),
                )
              ],
            ),
          );
        } else {
          Scaffold(
            body: Center(child: Text("Error!")),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _onMapCreated(controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _setMarker(LatLng coord) async {
    // get address
    String _markerAddress = await _getGeolocationAddress(
      Position(latitude: coord.latitude, longitude: coord.longitude),
    );

    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
          markerId: MarkerId(coord.toString()),
          position: coord,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: coord.toString(),
            snippet: _markerAddress,
          ),
        ),
      );
    });
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeolocationAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        infoWindow: InfoWindow(
          title: _currentPosition.toString(),
          snippet: _currentAddress,
        ),
      ),
    );

    // move camera
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address availabe";
  }
}
