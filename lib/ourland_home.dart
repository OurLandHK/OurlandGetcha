import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ourland_native/pages/topic_screen.dart';
import 'package:ourland_native/widgets/popup_menu.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/pages/send_topic_screen.dart';
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
  bool _isFabShow = true;
//  List<CameraDescription> cameras;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    this.uid = '';
    super.initState();
    _tabController = new TabController(vsync: this, initialIndex: 0, length: 3);
    _tabController.addListener(() {
      print('Index: ${_tabController.index}');
      switch(_tabController.index) {
        case 1:
          if(widget.user.homeAddress == null) {
            setState(() {
              this._isFabShow = false;
            });
          } else {
            setState(() {
              this._isFabShow = true;
            });            
          }
          break;
        case 2:
          if(widget.user.officeAddress == null) {
            setState(() {
              this._isFabShow = false;
            });
          } else {
            setState(() {
              this._isFabShow = true;
            });            
          }
          break;          
        default:
          setState(() {
            this._isFabShow = true;
          });
      }
    });

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

  @override
  Widget build(BuildContext context) {
    Widget showNearby() { 
      return new TopicScreen(user: widget.user);
    }
    Widget showHome() {
      Widget rv = new UpdateLocationScreen(locationType: LABEL_REGION0, user: widget.user);
      if(widget.user.homeAddress != null) {
        rv = new TopicScreen(user: widget.user, fixLocation: widget.user.homeAddress);
      }
      return rv;
    }
    Widget showOffice() {
      Widget rv = new UpdateLocationScreen(locationType: LABEL_REGION1, user: widget.user);
      if(widget.user.officeAddress != null) {
        rv = new TopicScreen(user: widget.user, fixLocation: widget.user.officeAddress);
      }
      return rv;
    }    
    void sendMessageClick() {
      GeoPoint messageLocation;
      /*
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
                text: LABEL_NEARBY,
              ),
              new Tab(
                text: LABEL_REGION0,
              ),
              new Tab(
                text: LABEL_REGION1,
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
            showNearby(),
            showHome(),
            showOffice()
            //new StatusScreen(),
          ],
        ),
        //persistentFooterButtons: <Widget>[SendMessage(chatModel: ChatModel(TOPIC_ROOT_ID), listScrollController: null, messageLocation: new GeoPoint(22.4, 114)),],
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
}
