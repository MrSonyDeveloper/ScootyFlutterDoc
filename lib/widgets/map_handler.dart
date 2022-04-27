import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../internet_engine.dart';
import '../model/parking_places.dart';
import '../model/transport.dart';
import 'marker_widget.dart';

class MapHandler extends StatelessWidget {
  final MapController mapController;
  List<ParkingPlaces> parking = [];
  List<Transport> transport = [];

  MapHandler(this.mapController, this.parking);

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    // LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // permission = await Geolocator.checkPermission();
    // if (permission == LocationPermission.denied) {
    //   permission = await Geolocator.requestPermission();
    //   if (permission == LocationPermission.denied) {
    //     return Future.error('Location permissions are denied');
    //   }
    // }
    //
    // if (permission == LocationPermission.deniedForever) {
    //   return Future.error(
    //       'Location permissions are permanently denied, we cannot request permissions.');
    // }
    return await Geolocator.getCurrentPosition();
  }

  Future<bool> setTransport(double _maxDist, double _batteryLevel) async {
    var position = await _determinePosition();
    parking = await InternetEngine().getTransport(
        position.latitude.toString(),
        position.longitude.toString(),
        _maxDist.toString(),
        _batteryLevel.toString());
    if (parking.isEmpty) {
      return false;
    }
    for (int i = 0; i < parking.length; i++) {
      List<Transport> transport = parking[i].transports;
      if (transport.isEmpty) {
      } else {
        addMarker(parking[i].latitude, parking[i].longitude, mapController);
        print('ok' + parking[i].toString());
      }
    }
    return true;
  }

  void addMarker(
      double latitude, double longitude, MapController mapController) {
    mapController.addMarker(GeoPoint(latitude: latitude, longitude: longitude),
        markerIcon: const MarkerIcon(iconWidget: MarkerWidget()));
  }

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -1, 0, 0, 0, 255, //
        0, -1, 0, 0, 255, //
        0, 0, -1, 0, 255, //
        0, 0, 0, 1, 0, //
      ]),
      child: OSMFlutter(
        controller: mapController,
        trackMyPosition: true,
        showZoomController: true,
        androidHotReloadSupport: true,
        initZoom: 18,
        onGeoPointClicked: (GeoPoint geoPoint) async{
          var position = await _determinePosition();
          parking = await InternetEngine().getTransport(
              position.latitude.toString(),
              position.longitude.toString(),
              10000.toString(),
              0.toString());
          for (var parkingPlace in parking) {
            if (parkingPlace.longitude == geoPoint.longitude &&
                parkingPlace.latitude == geoPoint.latitude) {
              transport = parkingPlace.transports;
            }
          }
          showModalBottomSheet(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            isScrollControlled: true,
            backgroundColor: Colors.black,
            context: context,
            builder: (context) {
              return StatefulBuilder(builder: (context, setModalState) {
                return Container(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(
                            height: 16,
                          ),
                          Center(
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                                color: Colors.white,
                              ),
                              height: 3,
                              width: 60,
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Container(
                              padding:
                                  const EdgeInsets.only(left: 16, right: 16),
                              child: Column(children: [
                                Text(transport[0].name,
                                    style: Theme.of(context).textTheme.subtitle1),
                              ]))
                        ]));
              });
            },
          );
        },
        userLocationMarker: UserLocationMaker(
          personMarker: const MarkerIcon(
            icon: Icon(
              MdiIcons.circleSmall,
              color: Color(0xff0014c4),
              size: 70,
            ),
          ),
          directionArrowMarker: const MarkerIcon(
            icon: Icon(
              Icons.double_arrow,
              size: 1,
            ),
          ),
        ),
        // roadConfiguration: RoadConfiguration(
        //   startIcon: const MarkerIcon(
        //     icon: Icon(
        //       CustomIcons.location,
        //       size: 64,
        //       color: Colors.brown,
        //     ),
        //   ),
        //   roadColor: Colors.yellowAccent,
        // ),
        // markerOption: MarkerOption(
        //     defaultMarker: const MarkerIcon(
        //   icon: Icon(
        //     CustomIcons.location,
        //     color: Colors.blue,
        //     size: 56,
        //   ),
        // )),
      ),
    );
  }
}