import 'package:flutter/material.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/report_service.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/widgets/property_selector_widget.dart';


// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class ReportScreen extends StatefulWidget  {
  final User user;
  final Topic topic;
  ReportScreen({@required this.topic, @required this.user});

  @override
  _ReportScreenState createState() => new _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  _ReportScreenState(
      {Key key}) {
        _selectedField = "";
      }
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ReportService _reportService;
  UserService _userService;
  List<Property> _properties = [];
  String _selectedField;

  @override
  void initState() {
    super.initState();
    _reportService = new ReportService(widget.user);
    _userService = new UserService();
    getReportValue();
  }

  void getReportValue() {
    List<Property> properties = [];
    // get the report value per topic
    setState(() {
      this._properties = properties;
    });
  }

  void selectField(List<String> selectField) {
    setState(() {
      if(selectField.length > 0) {
        _selectedField = selectField[0];
      } else {
        _selectedField = "";
      }
    });
    //print("Report: ${_selectedField}");
  }

  Widget renderOption() {
    return PropertySelectorWidget(BlockReasons, this._properties, 1, selectField, true, false);
  }

  void onApprove()  {
    /*
    if(_location != null && _location.length > 1) {
      _geolocator.placemarkFromAddress(_location).then(
          (List<Placemark> placemark) {
        Position pos = placemark[0].position;
        String markerLabel = placemark[0].name;
        setState(() {
          this._currentLocation = new GeoPoint(pos.latitude, pos.longitude);
        });
        //updateMap();
        refreshMarker(markerLabel);
      }, onError: (e) {
        // PlatformException thrown by the Geolocation if the address cannot be translate
        // DO NOTHING
      });
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    void onSubmit() {
      _reportService.sendUserReportResult(widget.topic.id, _selectedField).then((void v) {
        _scaffoldKey.currentState.showSnackBar(
            new SnackBar(content: new Text(UPDATE_LOCATION_SUCCESS)));
        _userService.addBlockTopic(widget.user.uuid, widget.topic.id, _selectedField).then((void v) {
          Navigator.of(context).pop();
        });
      });
    }
    List<Widget> widgets = [RaisedButton(
        onPressed: _selectedField != "" ? () => onSubmit() : null,
        child: Text(CHAT_MENU_ITEM_REPORT),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue)];
    if(widget.user != null && widget.user.globalHideRight) {
      widgets.add(RaisedButton(
        onPressed: () => onApprove(),
        child: Text(REPORT_APPROVED),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue));
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(widget.topic.topic),
      ),
      body: new Center(
        child: Container(
            child: Column(children: <Widget>[
          Text(REPORT_DESC, maxLines: 3),
          renderOption(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: widgets)
        ])),
      ),
    );
  }
}

// ----------------------------------------
// TODO: UPDATE PROFILE IMAGE SCREEN
// ----------------------------------------
