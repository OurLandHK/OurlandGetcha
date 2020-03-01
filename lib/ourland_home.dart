import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ourland_native/pages/topic_screen.dart';
import 'package:ourland_native/pages/searching_main.dart';
import 'package:ourland_native/widgets/popup_menu.dart';
import 'package:ourland_native/widgets/fab_bottom_app_bar.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/pages/send_topic_screen.dart';
import 'package:ourland_native/pages/broadcast_screen.dart';
import 'package:ourland_native/pages/send_message_screen.dart';
import 'package:ourland_native/pages/notification_screen.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

//final Map<String, Item> _items = <String, Item>{};


class Item {
  Item({@required this.topicID, @required this.topic, @required this.page});
  final String topicID;
  final String topic;
  final Widget page;

  StreamController<Item> _controller = StreamController<Item>.broadcast();
  Stream<Item> get onChanged => _controller.stream;

  String _status;
  String get status => _status;
  set status(String value) {
    _status = value;
    _controller.add(this);
  }

  static final Map<String, Route<void>> routes = <String, Route<void>>{};
  Route<void> get route {
    final String routeName = '/topic/$topicID';
    return routes.putIfAbsent(
      routeName,
      () => MaterialPageRoute<void>(
            settings: RouteSettings(name: routeName),
            builder: (BuildContext context) => page,
          ),
    );
  }
}

class OurlandHome extends StatefulWidget {
  final User user;
  final SharedPreferences preferences;

  OurlandHome(this.user, @required this.preferences) {
/*    if (user == null) {
      throw new ArgumentError("[OurlandHome] firebase user cannot be null.");
    }*/
  }

  @override
  _OurlandHomeState createState() => new _OurlandHomeState();
}

const String _app_name = APP_NAME;

class _OurlandHomeState extends State<OurlandHome> with TickerProviderStateMixin {
  TabController _tabController;
  List<String> _youtubeChannelList;
  String uid = '';
  bool _isFabShow = false;
  String _fabText = '';
//  List<CameraDescription> cameras;
  bool _locationPermissionGranted = true;
  bool _disableLocation = false;
  Widget _nearBySelection;
  Widget _pendingWidget;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  UserService userService = new UserService();
  MessageService messageService;
/*
  WebViewController _controller;
  WebView  _webView;
  WebviewScaffold _webviewPlugin;
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
*/
    // use to get current location
  GeoPoint _currentLocation = HongKongGeoPoint;

  StreamSubscription<Position> _positionStream;

  Geolocator _geolocator = new Geolocator();
  LocationOptions locationOptions = new LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  GeolocationStatus geolocationStatus = GeolocationStatus.denied;
  String error;

  @override
  void initState() {
    this.uid = '';
    _nearBySelection = new CircularProgressIndicator();
    messageService = new MessageService(widget.user);
    _tabController = new TabController(vsync: this, initialIndex: 0, length: 4);
    super.initState();
    _geolocator.checkGeolocationPermissionStatus().then((geolocationStatus) {
      PermissionHandler()
          .checkPermissionStatus(PermissionGroup.location)
          .then((PermissionStatus permission) {
        if (permission == PermissionStatus.granted) {
            _locationPermissionGranted = true;
        } else {
            _locationPermissionGranted = false;
        }
        if(_locationPermissionGranted) {
          _positionStream = _geolocator.getPositionStream(locationOptions).listen((Position position) {
            if(position != null) {
              _disableLocation = false;
              print('initState Poisition ${position}');
              _currentLocation = new GeoPoint(position.latitude, position.longitude);
              _nearBySelection = new TopicScreen(user: widget.user, getCurrentLocation: getCurrentLocation, preferences: widget.preferences);
              //_searchingMain = new SearchingMain(user: widget.user, getCurrentLocation: getCurrentLocation, preferences: widget.preferences, disableLocation: _disableLocation);
            }
          });
        }
        print('initState Poisition, updateLocation ${_currentLocation}');       // get GPS
        initPlatformState();

        // Firebase Messaging
        firebaseCloudMessaging_Listeners();
        //return Future<Null>;
      });
    });

    //updateLocation();
    // checking if location permission is granted
  }

  initPlatformState() async {
    Position location;
    messageService.getFirstPage().then((firstPage){
      setState(() {
        _youtubeChannelList = firstPage['YoutubeChannel'].cast<String>();
        print(firstPage['YoutubeChannel'].toString());
        print(_youtubeChannelList);
      });
    });
    // Platform messages may fail, so we use a try/catch PlatformException.
    if(_locationPermissionGranted) {
      try {
        //geolocationStatus = await _geolocator.checkGeolocationPermissionStatus();
        location = await _geolocator.getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
        error = null;
      } on PlatformException catch (e) {
        if (e.code == 'PERMISSION_DENIED') {
          error = 'Permission denied';
        } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
          error = 'Permission denied - please ask the user to enable it from the app settings';
        }
        print("GPS ${error}");
        location = null;
      }

      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      //if (!mounted) return;
      print('initPlatformStateLocation: ${location}');
      if(location != null) {
        setState(() {
            _disableLocation = false;
            _currentLocation = new GeoPoint(location.latitude, location.longitude);
            _nearBySelection = new TopicScreen(user: widget.user, getCurrentLocation: getCurrentLocation, preferences: widget.preferences);
            //_searchingMain = new SearchingMain(user: widget.user, getCurrentLocation: getCurrentLocation, preferences: widget.preferences);             
        });
      }
    }
  }

  Map getCurrentLocation() {
    GeoPoint geoPoint;
    if(_currentLocation != null) {
      geoPoint = _currentLocation; 
    } else {
      geoPoint = HongKongGeoPoint;
    }
    Map rv = new Map();
    rv['GeoPoint'] = geoPoint;
    rv['LocationPermissionGranted']  = _locationPermissionGranted;
    return rv;
  }

  void firebaseCloudMessaging_Listeners() {
  if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token){
      Map<String, String> field = new Map<String, String>();
      field['fcmToken'] = token;
      if(widget.user != null) {
        userService.updateUser(widget.user.uuid, field);
      }
      print(token);
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        var data = message['data'] == null ? message : message['data'];
        String id = data['id'];
        print('on message $message    data $data id $id');
        _showItemDialog(data);
      },
      onResume: (Map<String, dynamic> message) async {
        var data = message['data'] == null ? message : message['data'];
        String id = data['id'];
        print('on resume $message    data $data id $id');
        _navigateToItemDetail(data);
      },
      onLaunch: (Map<String, dynamic> message) async {
        var data = message['data'] == null ? message : message['data'];
        String id = data['id'];
        print('on launch $message    data $data id $id');
        _navigateToItemDetail(data);
      },
    );
  }

  Widget _buildDialog(BuildContext context, Item item) {
    return AlertDialog(
      content: Text(item.topic + LABEL_UPDATE_TOPIC),
      actions: <Widget>[
        FlatButton(
          child: const Text(LABEL_CLOSE),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        FlatButton(
          child: const Text(LABEL_SHOW),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  void _showItemDialog(Map<String, dynamic> data) {
    final String id = data['id'];
    //GeoPoint messageLocation = _currentLocation;
    this.messageService.getTopic(id).then((topic) {
      Widget page = new ChatScreen(user: widget.user, topic: topic, parentTitle: topic.topic);
      final Item item = new Item(page: page, topic: topic.topic, topicID: id);
      showDialog<bool>(
        context: context,
        builder: (_) => _buildDialog(context, item),
      ).then((bool shouldNavigate) {
        if (shouldNavigate == true) {
          Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
          if (!item.route.isCurrent) {
            Navigator.push(context, item.route);
          }      
        }
      });
    });
  }

  void _navigateToItemDetail(Map<String, dynamic> data) {
    // Clear away dialogs
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    final String id = data['id'];
    this.messageService.getTopic(id).then((topic) {
      Widget page = new ChatScreen(user: widget.user, topic: topic, parentTitle: topic.topic);
      final Item item = new Item(page: page, topic: topic.topic, topicID: id);
      if (!item.route.isCurrent) {
        Navigator.push(context, item.route);
      }      
    });
  }


  void iOS_Permission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true)
    );
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings)
    {
      print("Settings registered: $settings");
    });
  }

  requestLocationPermission() {
    return  _geolocator.checkGeolocationPermissionStatus().then((geolocationStatus) {
      print("Regest for Location" + geolocationStatus.toString());
      return PermissionHandler().requestPermissions([PermissionGroup.location]).then(
          (Map<PermissionGroup, PermissionStatus> permissions) {
        if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
          setState(() {
            _locationPermissionGranted = true;
          });
          return initPlatformState();
        }
      });
    });
  }

  noLocationPermission() {
    setState(() {
      _disableLocation = true;
    });
    Widget rv = showNearby();
    setState(() {
      this._nearBySelection = rv;
    });
  }
    // TODO for Real Notification Screen
  Widget showNotification() {
    return new NotificationScreen(user: widget.user);
  }

  Widget showBroadcast() {
    return new BroadcastScreen(user: widget.user, youtubeChannelList: _youtubeChannelList,);
  }  

  void updateLocation() {
    Widget rv;
    bool isFabShow = false;
    String fabText = "";
    if(widget.user != null) {
      isFabShow = true;
      fabText = LABEL_NEW_MEMO;
    }
    rv = showNearby();
    setState((){
      this._isFabShow = isFabShow;
      this._fabText = fabText;
      this._nearBySelection = rv;
    });
  }   

  Widget showNearby() {
    print('show Nearby ${_currentLocation}');
    Widget rv;
    if(_locationPermissionGranted == true || _disableLocation == true) {
      rv = new TopicScreen(user: widget.user, getCurrentLocation: getCurrentLocation, preferences: widget.preferences);
    } else {
      rv = new CircularProgressIndicator();
    }
    return rv;
  }

  @override
  Widget build(BuildContext context) {
    _tabController.addListener(() {
      switch(_tabController.index) {
        case 0:
        case 3:
          if(widget.user != null && widget.user.sendBroadcastRight != null && widget.user.sendBroadcastRight) {
            setState(() {
              this._isFabShow = true;
              this._fabText = LABEL_NEW_BROADCAST;
            });
          } else {
            setState(() {
              this._isFabShow = false;
              this._fabText = "";
            });            
          }
          break; 
        case 2:
          setState(() {
            this._isFabShow = true;
            this._fabText = LABEL_NEW_MESSAGE;
            //this._isFabShow = false;
          });
          break;
        default:
          updateLocation();
      }
    });
    void sendMessageClick() {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            switch(_tabController.index) {
              case 0:
                return new SendTopicScreen(
                  getCurrentLocation: null, user: widget.user, isBroadcast: true, dropdownList: _youtubeChannelList);
                break;
              case 1:
                  return new SendTopicScreen(
                getCurrentLocation: getCurrentLocation, user: widget.user, isBroadcast: false, dropdownList: TAG_SELECTION);
              case 2:
                return new SendMessageScreen(
                  getCurrentLocation: getCurrentLocation, user: widget.user, searchingMsg: null);
                break;
              case 3:
                return new SendTopicScreen(
                getCurrentLocation: getCurrentLocation, user: widget.user, isBroadcast: true, dropdownList: TAG_SELECTION);
            }
          },
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => updateAnyMarkerChange(context));

    if (_locationPermissionGranted == true || _disableLocation == true) {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text(_app_name),
          elevation: 0.7,
          actions: <Widget>[
            //new Icon(Icons.search),
            new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
            ),
            new PopupMenu(widget.user, widget.preferences)
          ],
        ),
        body: new TabBarView(
          physics: NeverScrollableScrollPhysics(),
          controller: _tabController,
          children: <Widget>[
            showBroadcast(),
            _nearBySelection,
            SearchingMain(user: widget.user, getCurrentLocation: getCurrentLocation, preferences: widget.preferences, disableLocation: _disableLocation),
            showNotification(),
            //new CircularProgressIndicator(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton:  new Opacity(
            opacity: _isFabShow ? 1.0 : 0.0,
            child: new FloatingActionButton(
              backgroundColor: Theme.of(context).accentColor,
              child: new Icon(
                  Icons.note_add,
                  color: Colors.black,
                ),
              onPressed: () => sendMessageClick(),
            )
        ),
        bottomNavigationBar: FABBottomAppBar(
          centerItemText: _fabText,
          backgroundColor: Theme.of(context).primaryColor,
          selectedColor: Theme.of(context).accentColor,
          notchedShape: _isFabShow ? CircularNotchedRectangle() : null,
          onTabSelected: (_selectedTab) => _tabController.index = _selectedTab,
          items: [
            FABBottomAppBarItem(iconData: Icons.layers, text: LABEL_CARE),
            FABBottomAppBarItem(iconData: Icons.dashboard, text: LABEL_LENNON_WALL),
            FABBottomAppBarItem(iconWidget: Image.asset(SEARCHING_APP_LOGO_IMAGE_PATH), text: ''),
            FABBottomAppBarItem(iconData: Icons.bookmark, text: LABEL_BOOKMARK),
          ],
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
            new RaisedButton(
              padding: const EdgeInsets.all(8.0),
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: noLocationPermission,
              child: new Text(PERM_LOCATION_NOT_GRANT_BTN_TEXT),
            ),            
          ],
        )),
      );
    }
  }

  
  void updateAnyMarkerChange(BuildContext context) {
    //print('swap ${_pendingWidget}');
    if(_pendingWidget != null) {
      Widget temp = _pendingWidget;
      setState(() {
        _pendingWidget = null;
        _nearBySelection = temp;
      });
    }
  }
}
