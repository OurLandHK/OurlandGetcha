import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ourland_native/pages/topic_screen.dart';
import 'package:ourland_native/widgets/popup_menu.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/pages/send_topic_screen.dart';
import 'package:ourland_native/pages/notification_screen.dart';
import 'package:ourland_native/pages/settings.dart';

class OurlandHome extends StatefulWidget {
  final User user;

  OurlandHome(this.user) {
    if (user == null) {
      throw new ArgumentError("[OurlandHome] firebase user cannot be null.");
    }
  }

  @override
  _OurlandHomeState createState() => new _OurlandHomeState();
}

const String _app_name = "我地.佳招";

class _OurlandHomeState extends State<OurlandHome>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  String uid = '';
  String _currentLocationSelection;
  List<DropdownMenuItem<String>> _locationDropDownMenuItems;
  bool _isFabShow = true;
//  List<CameraDescription> cameras;
  bool _locationPermissionGranted = false;
  Widget _nearBySelection;
  Widget _pendingWidget;

  @override
  void initState() {
    this.uid = '';
    super.initState();
    List<String> dropDownList = [LABEL_NEARBY, LABEL_REGION0, LABEL_REGION1];
    _locationDropDownMenuItems = getDropDownMenuItems(dropDownList);
    _currentLocationSelection = _locationDropDownMenuItems[0].value;

    _tabController = new TabController(vsync: this, initialIndex: 0, length: 2);
    _tabController.addListener(() {
      switch(_tabController.index) {
        case 1:
          print("${widget.user.sendBroadcastRight}");
          if(widget.user.sendBroadcastRight != null && widget.user.sendBroadcastRight) {
            setState(() {
              this._isFabShow = true;
            });
          } else {
            setState(() {
              this._isFabShow = false;
            });            
          }
          break;       
        default:
          updateLocation(_currentLocationSelection);
      }
    });
    _nearBySelection = new TopicScreen(user: widget.user);
    // checking if location permission is granted
    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.location)
        .then((PermissionStatus permission) {
      if (permission == PermissionStatus.granted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      } else {
        requestLocationPermission();
      }
    });
  }

  requestLocationPermission() {
    PermissionHandler().requestPermissions([PermissionGroup.location]).then(
        (Map<PermissionGroup, PermissionStatus> permissions) {
      if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      }
    });
  }

  
  List<DropdownMenuItem<String>> getDropDownMenuItems(List<String> labelList) {
    List<DropdownMenuItem<String>> items = new List();
    for (String label in labelList) {
      items.add(new DropdownMenuItem(
          value: label,
          child: new Text(label)
      ));
    }
    return items;
  }

  Widget showNearby() {
    _pendingWidget = new TopicScreen(user: widget.user);
    return new CircularProgressIndicator();
  }
  Widget showHome() {
    Widget rv = new UpdateLocationScreen(locationType: LABEL_REGION0, user: widget.user);
    if(widget.user.homeAddress != null) {
      _pendingWidget = new TopicScreen(user: widget.user, fixLocation: widget.user.homeAddress);
      rv = new CircularProgressIndicator();
    }
    return rv;
  }
  Widget showOffice() {
    Widget rv = new UpdateLocationScreen(locationType: LABEL_REGION1, user: widget.user);
    if(widget.user.officeAddress != null) {
      _pendingWidget = TopicScreen(user: widget.user, fixLocation: widget.user.officeAddress);
      rv = new CircularProgressIndicator();
    }
    return rv;
  }

    // TODO for Real Notification Screen
  Widget showNotification() {
    return new NotificationScreen(user: widget.user);
  }

  void updateLocation(String locationSelection) {
    Widget rv;
    bool isFabShow;
    switch(locationSelection) {
      case LABEL_REGION0:
        rv = showHome();
        //_nearBySelection.setLocation(widget.user.homeAddress);
        if(widget.user.homeAddress == null) {
          isFabShow = false;
        } else {
          isFabShow = true;         
        }
        break;
      case LABEL_REGION1:
        rv = showOffice();
        //_nearBySelection.setLocation(widget.user.officeAddress);
        if(widget.user.officeAddress == null) {
          isFabShow = false;
        } else {
          isFabShow = true;           
        }
        break;          
      default:
        isFabShow = true;
        rv = showNearby();
        //_nearBySelection.setLocation(null);
        
    }                
    setState((){
      _currentLocationSelection = locationSelection;
      this._isFabShow = isFabShow;
      _nearBySelection = rv;
      _tabController.index = 0;
    });
  } 

  @override
  Widget build(BuildContext context) {
    void sendMessageClick() {
      GeoPoint messageLocation;

      /* Need to base on tab to decide send broadcast message or personal.
      switch(_tabController.index) {
        case 1:
          messageLocation = widget.user.homeAddress;
          break;
        case 2:
          messageLocation = widget.user.officeAddress;
          break;
      }
      */
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new SendTopicScreen(
                messageLocation: messageLocation, user: widget.user);
          },
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => updateAnyMarkerChange(context));

    if (_locationPermissionGranted == true) {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text(_app_name),
          elevation: 0.7,
          bottom: new TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: <Widget>[
              //  new Tab(icon: new Icon(Icons.camera_alt)),
              new Tab(
                child: new Row(
                  children: [
                    new Icon(Icons.location_city),
                    new Text(" "),
                    new DropdownButton(
                    value: _currentLocationSelection,
                    items: _locationDropDownMenuItems,
                    onChanged: updateLocation,
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                )
              ),
              new Tab(
                icon: new Icon(Icons.alarm),
              ),
            ],
          ),
          actions: <Widget>[
            //new Icon(Icons.search),
            new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
            ),
            new PopupMenu(widget.user)
          ],
        ),
        body: new TabBarView(
          controller: _tabController,
          children: <Widget>[
            //new CameraScreen(widget.cameras),
            _nearBySelection,
            showNotification()
            //new StatusScreen(),
          ],
        ),
        floatingActionButton:  new Opacity(
            opacity: _isFabShow ? 1.0 : 0.0,
            child: new FloatingActionButton(
              backgroundColor: Theme.of(context).accentColor,
              child: new Icon(
                  Icons.note_add,
                  color: Colors.white,
                ),
              onPressed: () => sendMessageClick(),
            )
        ),
      );
    } else {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text(_app_name),
          elevation: 0.7,
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Text(PERM_LOCATION_NOT_GRANTED),
            new RaisedButton(
              padding: const EdgeInsets.all(8.0),
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: requestLocationPermission,
              child: new Text(PERM_LOCATION_GRANT_BTN_TEXT),
            ),
          ],
        )),
      );
    }
  }
  void updateAnyMarkerChange(BuildContext context) {
    if(_pendingWidget != null) {
      Widget temp = _pendingWidget;
      setState(() {
        _pendingWidget = null;
        _nearBySelection = temp;
      });
    }
  }
}
