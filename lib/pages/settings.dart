import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ourland_native/pages/chat_map.dart';
import 'package:ourland_native/models/constant.dart';

// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class SettingsScreen extends StatelessWidget {
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
            return new UpdateLocationScreen(locationType: LABEL_REGION0);
          },
        ),
      );
    } else if (item == MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new UpdateLocationScreen(locationType: LABEL_REGION1);
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

  UpdateLocationScreen({Key key, @required this.locationType});

  @override
  _UpdateLocationScreenState createState() =>
      new _UpdateLocationScreenState(locationType: this.locationType);
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  _UpdateLocationScreenState({Key key, @required this.locationType});

  String locationType;
  String _location;
  ChatMap chatMap = null;
  Geolocator _geolocator = new Geolocator();
  GeoPoint currentLocation;

  @override
  void initState() {
    super.initState();

    // get current location
    _geolocator.getCurrentPosition().then((Position position) {
      setState(() {
        currentLocation = new GeoPoint(position.latitude, position.longitude);
      });
      updateChatMap();
    });
  }

  void updateChatMap() {
    if (this.chatMap == null) {
      this.chatMap = new ChatMap(
          topLeft: this.currentLocation,
          bottomRight: this.currentLocation,
          height: MAP_HEIGHT);
    } else {
      this.chatMap.updateCenter(currentLocation);
    }
  }

  void onSubmit() {}

  Widget renderMap() {
    return this.chatMap;
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
            print(placemark[0].country);
            print(placemark[0].position);
            print(placemark[0].locality);
            print(placemark[0].administrativeArea);
            print(placemark[0].postalCode);
            print(placemark[0].name);
            print(placemark[0].isoCountryCode);
            print(placemark[0].subLocality);
            print(placemark[0].subThoroughfare);
            print(placemark[0].thoroughfare);
          }, onError: (e) {
            // PlatformException thrown by the Geolocation if the address cannot be translate
            // DO NOTHING
          });
        },
        keyboardType: TextInputType.text);
  }

  Widget renderLocationButton() {
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
          renderLocationButton()
        ])),
      ),
    );
  }
}

// ----------------------------------------
// TODO: UPDATE PROFILE IMAGE SCREEN
// ----------------------------------------
