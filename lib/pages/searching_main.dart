import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/pages/searching_screen.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/widgets/searching_widget.dart';
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
  final bool disableLocation;
  String _streetAddress;
  Widget _searchingScreen;
  Geolocator _geolocator = new Geolocator();
  SearchingMain({Key key, @required this.user, @required this.getCurrentLocation, @required this.preferences, this.fixLocation, @required this.disableLocation}) : super(key: key) {
    _searchingScreen = Container();
  }

  @override
  Widget build(BuildContext context) {
    void onPressed(context, tag)  {
      GeoPoint newLocation; 
      if(_streetAddress != null && _streetAddress.length > 0) {
      _geolocator.placemarkFromAddress(_streetAddress).then((List<Placemark> placemark) {
        Position pos = placemark[0].position;
        newLocation = new GeoPoint(pos.latitude, pos.longitude);
        Navigator.of(context).push(
          new MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return new SearchingScreen(user: user, getCurrentLocation: getCurrentLocation, preferences: preferences, fixLocation: newLocation, streetAddress: _streetAddress, tag: tag);
            },
          ),
        );
      }, onError: (e) {
      });
      } else {
        Navigator.of(context).push(
          new MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return new SearchingScreen(user: user, getCurrentLocation: getCurrentLocation, preferences: preferences, fixLocation: newLocation, tag: tag);
            },
          ),
        );
      }
    }
/*
    void onSubmitted() {
      setState(() {_streetAddress = value});
    }
*/
    Widget renderLocationField() {
      bool _isSubmitDisable = true;
      if((_streetAddress != null && _streetAddress.length > 0) || this.disableLocation == false) {
        _isSubmitDisable = false;
      }
      return PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: Row(children: [SizedBox(width: 12.0), Expanded(child: TextField(
                  decoration: InputDecoration(
                      hintText: HINT_SEARCH_LOCATION),
                  keyboardType: TextInputType.text,
                  onChanged: (value) {_streetAddress = value;})),
                  //onChanged: (value) {setState(() {_streetAddress = value;});},
                  //onSubmitted: onSubmitted)), 
                  Material(child: Container(
                    decoration: BoxDecoration(
                          border: Border.all(width: 0.5, color: Colors.grey),
                        ),
                      child: IconButton(icon: Icon(Icons.location_searching), onPressed: _isSubmitDisable ? null : () => onPressed(context, "")))),
                  SizedBox(width: 12.0)]));
    }

    Row renderTagButtons(List<String> tags) {
      bool _isSubmitDisable = true;
      if((_streetAddress != null && _streetAddress.length > 0) || this.disableLocation == false) {
        _isSubmitDisable = false;
      }
      List<Widget> widgets = tags
                .map((tag) => Expanded(
                  //flex: 1,
                  child:OutlineButton(
                      child: Text(tag),
                      
                      onPressed: _isSubmitDisable ? null : () => onPressed(context, tag),
                      borderSide: BorderSide(
                        color: Colors.blue, //Color of the border
                        style: BorderStyle.solid, //Style of the border
                        width: 0.8, //width of the border
                      )
                    ))
                )
                .toList();
      return(Row(children: widgets));
    }

    List<String> firstButtonRow = TagList.sublist(0, (TagList.length/2).round());
    List<String> secondButtonRow = TagList.sublist((TagList.length/2).round(), TagList.length);

    return Scaffold(
        
        appBar: renderLocationField(),
        body: Column(children: [
              renderTagButtons(firstButtonRow),
              renderTagButtons(secondButtonRow)
          ]));
  } 
}
