import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ourland_native/pages/chat_map.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/models/user_model.dart';

// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class SettingsScreen extends StatelessWidget {
  final User user;
  SettingsScreen(this.user);

  List<String> _settingsItems = [
    MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION,
    MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION,
    MENU_ITEM_SETTINGS_CHANGE_PROFILE_IMAGE,
  ];

  void onTapped(BuildContext context, String item) {
    if (item == MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new UpdateLocationScreen(
                locationType: LABEL_REGION0, user: this.user);
          },
        ),
      );
    } else if (item == MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new UpdateLocationScreen(
                locationType: LABEL_REGION1, user: this.user);
          },
        ),
      );
    } else if (item == MENU_ITEM_SETTINGS_CHANGE_PROFILE_IMAGE) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            // TODO: update it when the screen is available
            return new Container();
          },
        ),
      );
    } else {
      throw MENU_ITEM_NOT_FOUND_ERR;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text(MENU_ITEM_SETTINGS),
        ),
        body: ListView(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            children: _settingsItems
                .map((settingItem) => ListTile(
                      title: Text(settingItem),
                      onTap: () => onTapped(context, settingItem),
                    ))
                .toList()));
  }
}

// ----------------------------------------
// UPDATE LOCATION SCREEN
// ----------------------------------------

class UpdateLocationScreen extends StatefulWidget {
  final String locationType;
  final User user;

  UpdateLocationScreen(
      {Key key, @required this.user, @required this.locationType});

  @override
  _UpdateLocationScreenState createState() => new _UpdateLocationScreenState(
      user: this.user, locationType: this.locationType);
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  _UpdateLocationScreenState(
      {Key key, @required this.user, @required this.locationType});
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  UserService userService = new UserService();
  String locationType;
  User user;
  String _location;
  ChatMap map = null;
  Geolocator _geolocator = new Geolocator();
  GeoPoint _currentLocation;

  @override
  void initState() {
    super.initState();
    initMap();
  }

  void initMap() {
    GeoPoint address;
    if (locationType == LABEL_REGION0) {
      address = user.homeAddress;
    } else {
      address = user.officeAddress;
    }

    if (address == null) {
      // home / location address not set. get current location instead
      _geolocator.getCurrentPosition().then((Position position) {
        setState(() {
          this._currentLocation =
              new GeoPoint(position.latitude, position.longitude);
        });
        updateMap();
      });
    } else {
      setState(() {
        this._currentLocation = address;
      });
      updateMap();
    }
  }

  void updateMap() {
    if (this.map == null) {
      this.map = new ChatMap(
          topLeft: this._currentLocation,
          bottomRight: this._currentLocation,
          height: MAP_HEIGHT);
    } else {
      this.map.updateCenter(this._currentLocation);
    }
  }

  void refreshMarker(String label) {
    this.map.clearMarkers();
    this.map.addMarker(this._currentLocation, label);
  }

  void onSubmit() {
    Map<String, GeoPoint> newLocation = new Map<String, GeoPoint>();
    if (locationType == LABEL_REGION0) {
      newLocation['homeAddress'] = this._currentLocation;
    } else {
      newLocation['officeAddress'] = this._currentLocation;
    }
    // TODO: should return a updated user object and pass it to home
    userService.updateUser(this.user.uuid, newLocation);
    // FIXME: snackbar is not shown at this moment
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(UPDATE_LOCATION_SUCCESS)));
    // TODO: tmp pop twice to navigate back home
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  Widget renderMap() {
    return this.map;
  }

  Widget renderLocationField() {
    return new TextField(
        decoration: InputDecoration(
            hintText: locationType == LABEL_REGION0
                ? NEW_HOME_LOCATION
                : NEW_OFFICE_LOCATION),
        onChanged: (value) {
          _location = value;

          _geolocator.placemarkFromAddress(_location).then(
              (List<Placemark> placemark) {
            Position pos = placemark[0].position;
            String markerLabel = placemark[0].name;
            setState(() {
              this._currentLocation = new GeoPoint(pos.latitude, pos.longitude);
            });
            updateMap();
            refreshMarker(markerLabel);
          }, onError: (e) {
            // PlatformException thrown by the Geolocation if the address cannot be translate
            // DO NOTHING
          });
        },
        keyboardType: TextInputType.text);
  }

  Widget renderUpdateLocationButton() {
    return new RaisedButton(
        onPressed: () => onSubmit(),
        child: Text(UPDATE_LOCATION_BTN_TEXT),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(locationType == LABEL_REGION0
            ? MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION
            : MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION),
      ),
      body: new Center(
        child: Container(
            child: Column(children: <Widget>[
          renderMap(),
          renderLocationField(),
          renderUpdateLocationButton()
        ])),
      ),
    );
  }
}

// ----------------------------------------
// TODO: UPDATE PROFILE IMAGE SCREEN
// ----------------------------------------
