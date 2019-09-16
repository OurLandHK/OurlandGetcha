import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/pages/searching_screen.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class SearchingMain extends StatelessWidget {
  final GeoPoint fixLocation;
  final User user;
  final Function getCurrentLocation;
  final SharedPreferences preferences;
  String _location;
  Widget _searchingScreen;
  Geolocator _geolocator = new Geolocator();
  SearchingMain({Key key, @required this.user, @required this.getCurrentLocation, @required this.preferences, this.fixLocation}) : super(key: key) {
    _searchingScreen = Container();
  }


  List<String> _tagItems = [
    MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION,
    MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION,
/*    MENU_ITEM_SETTINGS_CHANGE_PROFILE_IMAGE, */
  ];
/*
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
    } else {
      throw MENU_ITEM_NOT_FOUND_ERR;
    }
  }
*/
  
  @override
  Widget build(BuildContext context) {
    void onPressed()  {
      GeoPoint newLocation; 
      if(_location != null && _location.length > 0) {
      _geolocator.placemarkFromAddress(_location).then((List<Placemark> placemark) {
        Position pos = placemark[0].position;
        newLocation = new GeoPoint(pos.latitude, pos.longitude);
        Navigator.of(context).push(
          new MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return new SearchingScreen(user: user, getCurrentLocation: getCurrentLocation, preferences: preferences, fixLocation: newLocation, streetAddress: _location);
            },
          ),
        );
      }, onError: (e) {
      });
      } else {
        Navigator.of(context).push(
          new MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return new SearchingScreen(user: user, getCurrentLocation: getCurrentLocation, preferences: preferences, fixLocation: newLocation);
            },
          ),
        );
      }
    }

    Widget renderLocationField() {
      return PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: Row(children: [SizedBox(width: 12.0), Expanded(child: TextField(
                  decoration: InputDecoration(
                      hintText: HINT_SEARCH_LOCATION),
                  keyboardType: TextInputType.text,
                  onChanged: (value) {_location = value;})),
                  //onChanged: (value) {setState(() {_location = value;});},
                  //onSubmitted: onSubmitted)), 
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
                  SizedBox(width: 12.0)]));
    }
    /*
    return Column(children: [
          renderLocationField(),
          ListView(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            children: _tagItems
                .map((settingItem) => ListTile(
                      title: Text(settingItem),
                     // onTap: () => onTapped(context, settingItem),
                    ))
                .toList())]);
                */

    return Scaffold(
        appBar: renderLocationField(),
        body: Container());
        /*
        body: Column(children: [
          //renderLocationField(),
          ListView(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            children: _tagItems
                .map((settingItem) => ListTile(
                      title: Text(settingItem),
                     // onTap: () => onTapped(context, settingItem),
                    ))
                .toList())]));
                */
                
  } 
}
