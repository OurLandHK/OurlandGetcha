import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/ourland_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ourland_native/pages/userlist_screen.dart';

// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class SettingsScreen extends StatelessWidget {
  final User user;
  final SharedPreferences preferences;
  SettingsScreen(this.user, this.preferences);

  List<String> _settingsItems = [
    MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION,
    MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION,
    TITLE_BLOCK,
/*    MENU_ITEM_SETTINGS_CHANGE_PROFILE_IMAGE, */
  ];

  void onTapped(BuildContext context, String item) {
    if (item == MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new UpdateLocationScreen(
                locationType: LABEL_REGION0, user: this.user, preferences: this.preferences);
          },
        ),
      );
    } else if (item == MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new UpdateLocationScreen(
                locationType: LABEL_REGION1, user: this.user, preferences: this.preferences);
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
    } else if (item == TITLE_BLOCK) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            // TODO: update it when the screen is available
            return new UserlistScreen(currentUser: this.user, userIdList: this.user.blockUsers, title: TITLE_BLOCK);
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
  final SharedPreferences preferences;

  UpdateLocationScreen(
      {Key key, @required this.user, @required this.locationType, @required this.preferences});

  @override
  _UpdateLocationScreenState createState() => new _UpdateLocationScreenState(
      user: this.user, locationType: this.locationType);
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  _UpdateLocationScreenState(
      {Key key, @required this.user, @required this.locationType}) {
        this._label = this.locationType;
      }
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  UserService userService = new UserService();
  String locationType;
  User user;
  String _location;
  String _label;
  ChatMap map;
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
        //updateMap();
      });
    } else {
      setState(() {
        this._currentLocation = address;
      });
      //updateMap();
    }
  }

  void refreshMarker(String label) {
    setState(() {
      _label = label;
    });

    /*
    this.map.clearMarkers();
    this.map.addMarker(this._currentLocation, label, "settings");
    */
  }

  void onSubmit() {
    Map<String, GeoPoint> newLocation = new Map<String, GeoPoint>();
    if (locationType == LABEL_REGION0) {
      newLocation['homeAddress'] = this._currentLocation;
      this.user.setHomeAddress(this._currentLocation);
    } else {
      newLocation['officeAddress'] = this._currentLocation;
      this.user.setOfficeAddress(this._currentLocation);
    }

    userService.updateUser(this.user.uuid, newLocation).then((void v) {
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: new Text(UPDATE_LOCATION_SUCCESS)));

      userService.getUser(this.user.uuid).then((User user) {
        Navigator.of(context).pushReplacement(
            new MaterialPageRoute(builder: (context) => OurlandHome(user, widget.preferences)));
      });
    });
  }

  Widget renderMap() {
    if(this._currentLocation == null) {
      return Container();
    } else {
      return ChatMap(
          topLeft: this._currentLocation,
          bottomRight: this._currentLocation,
          height: MAP_HEIGHT,
          markerList: [OurlandMarker(_label, this._currentLocation, 0, _label, "settings")],
          updateCenter: null,);
   }
  }

  Widget renderLocationField() {
    return Row(children: [SizedBox(width: 12.0), Expanded(child: TextField(
        decoration: InputDecoration(
            hintText: locationType == LABEL_REGION0
                ? NEW_HOME_LOCATION
                : NEW_OFFICE_LOCATION),
        keyboardType: TextInputType.text,
        onChanged: (value) {setState(() {_location = value;});},
        onSubmitted: onSubmitted)), 
        Material(child: Container(
          decoration: BoxDecoration(
                border: Border.all(width: 0.5, color: Colors.grey),
                /*
                boxShadow: [
                  new BoxShadow(
                    color: Colors.grey,
                    offset: new Offset(0.0, 2.5),
                    blurRadius: 4.0,
                    spreadRadius: 0.0
                  )
                ],
                */  //borderRadius: BorderRadius.circular(6.0)
              ),
            child: IconButton(icon: Icon(Icons.location_searching), onPressed: onPressed))),
        SizedBox(width: 12.0)]);
  }

  void onSubmitted(String dummy) {
    onPressed();
  }

  void onPressed()  {
    if(_location != null && _location.length > 1) {
      _geolocator.placemarkFromAddress(_location,localeIdentifier: "zh_HK").then(
          (List<Placemark> placemark) {
        Position pos = placemark[0].position;
        String markerLabel = placemark[0].name;
        setState(() {
          this._currentLocation = new GeoPoint(pos.latitude, pos.longitude);
        });
        //updateMap();
        refreshMarker(markerLabel);
      }, onError: (e) {
        _geolocator.placemarkFromAddress(_location,localeIdentifier: "en_HK").then(
            (List<Placemark> placemark) {
          Position pos = placemark[0].position;
          String markerLabel = placemark[0].name;
          setState(() {
            this._currentLocation = new GeoPoint(pos.latitude, pos.longitude);
          });
          //updateMap();
          refreshMarker(markerLabel);
        }, onError: (e) {
          _scaffoldKey.currentState.showSnackBar(
              new SnackBar(content: new Text(NO_PLACE_CALLED + _location)));
        });
      });
    }
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
