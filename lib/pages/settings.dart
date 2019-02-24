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
    if(item == MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new UpdateLocationScreen();
          },
        ),
      );
    } else if(item == MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION){
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new UpdateLocationScreen();
          },
        ),
      );
    } else if(item == MENU_ITEM_SETTINGS_CHANGE_PROFILE_IMAGE) {
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
        body:  ListView(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: _settingsItems.map((settingItem) =>
            ListTile(
            title: Text(settingItem),
              onTap: () => onTapped(context, settingItem),
        ))
            .toList()
        )
    );
  }
}

// ----------------------------------------
// UPDATE LOCATION SCREEN
// ----------------------------------------

class UpdateLocationScreen extends StatefulWidget {
  @override
  _UpdateLocationScreenState createState() => new _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
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

  Widget renderMap() {
    return this.chatMap;
  }

  Widget renderLocationField() {
    return new Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Settings"),
      ),
      body: new Center(
        child: Container(
            child: Column(children: <Widget>[
          renderMap(),
        ])),
      ),
    );
  }
}


// ----------------------------------------
// TODO: UPDATE PROFILE IMAGE SCREEN
// ----------------------------------------