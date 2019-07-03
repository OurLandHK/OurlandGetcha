import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ourland_native/pages/topic_screen.dart';
import 'package:ourland_native/widgets/popup_menu.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/pages/send_topic_screen.dart';
import 'package:ourland_native/pages/notification_screen.dart';
import 'package:ourland_native/pages/settings.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:geolocator/geolocator.dart';

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

  OurlandHome(this.user) {
    if (user == null) {
      throw new ArgumentError("[OurlandHome] firebase user cannot be null.");
    }
  }

  @override
  _OurlandHomeState createState() => new _OurlandHomeState();
}

const String _app_name = APP_NAME;

class _OurlandHomeState extends State<OurlandHome> with TickerProviderStateMixin {
  TabController _tabController;
  String uid = '';
  bool _isFabShow = true;
//  List<CameraDescription> cameras;
  bool _locationPermissionGranted = true;
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
  GeoPoint _currentLocation;

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
    /*
    _webView = new WebView(
                initialUrl: OUTLAND_SEARCH_HOST,
                onWebViewCreated: (WebViewController webViewController) {
                  _controller = webViewController;
                },
                javascriptMode: JavascriptMode.unrestricted,
              );
    _webviewPlugin = new WebviewScaffold(url: OUTLAND_SEARCH_HOST, geolocationEnabled: true, appCacheEnabled: true, supportMultipleWindows: true, withJavascript: true, withLocalStorage: true,);
    */
    super.initState();
    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.location)
        .then((PermissionStatus permission) {
      if (permission == PermissionStatus.granted) {
          _locationPermissionGranted = true;
      } else {
          _locationPermissionGranted = false;
        requestLocationPermission();
      }
    });
    // get GPS
    initPlatformState();
    if(_locationPermissionGranted) {
      _positionStream = _geolocator.getPositionStream(locationOptions).listen((Position position) {
        if(position != null) {
          print('initState Poisition ${position}');
          setState(() {
            _currentLocation = new GeoPoint(position.latitude, position.longitude);
            _nearBySelection = new TopicScreen(user: widget.user, getCurrentLocation: getCurrentLocation);
          });
        }
      });
    }

    // Firebase Messaging
    firebaseCloudMessaging_Listeners();

    _tabController = new TabController(vsync: this, initialIndex: 0, length: 3);
    print('initState Poisition, updateLocation ${_currentLocation}');
    //updateLocation();
    // checking if location permission is granted
  }

  initPlatformState() async {
    Position location;
    // Platform messages may fail, so we use a try/catch PlatformException.
    if(_locationPermissionGranted) {
      try {
        geolocationStatus = await _geolocator.checkGeolocationPermissionStatus();
        location = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
        error = null;
      } on PlatformException catch (e) {
        if (e.code == 'PERMISSION_DENIED') {
          error = 'Permission denied';
        } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
          error = 'Permission denied - please ask the user to enable it from the app settings';
        }

        location = null;
      }

      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      //if (!mounted) return;

      setState(() {
          print('initPlatformStateLocation: ${location}');
          if(location != null) {
            _currentLocation = new GeoPoint(location.latitude, location.longitude);
            _nearBySelection = new TopicScreen(user: widget.user, getCurrentLocation: getCurrentLocation);
            //updateLocation();
          }
      });
    }
  }

  GeoPoint getCurrentLocation() {
    GeoPoint rv;
    if(_currentLocation != null) {
      rv = _currentLocation; 
    } else {
      rv = new GeoPoint(22.266455999999998, 114.23257000000001);
    }
    return rv;
  }

  void firebaseCloudMessaging_Listeners() {
  if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token){
      Map<String, String> field = new Map<String, String>();
      field['fcmToken'] = token;
      userService.updateUser(widget.user.uuid, field);
      print(token);
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        // on message {notification: {title: null, body: {'id': '1553099389364'}}, data: {}}
        var data = message['data'];
        String id = data['id'];
        print('on message $message    data $data id $id');
        _showItemDialog(message);
      },
      onResume: (Map<String, dynamic> message) async {
        // on resume {notification: {}, data: {collapse_key: hk.ourland.wall, google.original_priority: high, google.sent_time: 1553878529834, google.delivered_priority: high, google.ttl: 2419200, from: 757324443294, id: 1553099389364, click_action: FLUTTER_NOTIFICATION_CLICK, google.message_id: 0:1553878530232073%41221c0241221c02}}
        var data = message['data'];
        String id = data['id'];
        print('on resume $message    data $data id $id');
        _navigateToItemDetail(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        var data = message['data'];
        String id = data['id'];
        print('on launch $message    data $data id $id');
        _navigateToItemDetail(message);
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

  void _showItemDialog(Map<String, dynamic> message) {
    final String id = message['data']['id'];
    GeoPoint messageLocation = _currentLocation;
    this.messageService.getTopic(id).then((topic) {
      Widget page = new ChatScreen(user: widget.user, topic: topic, parentTitle: topic.topic, messageLocation: messageLocation);
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

  void _navigateToItemDetail(Map<String, dynamic> message) {
    // Clear away dialogs
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    final String id = message['data']['id'];
    GeoPoint messageLocation = _currentLocation;
    this.messageService.getTopic(id).then((topic) {
      Widget page = new ChatScreen(user: widget.user, topic: topic, parentTitle: topic.topic, messageLocation: messageLocation);
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
    PermissionHandler().requestPermissions([PermissionGroup.location]).then(
        (Map<PermissionGroup, PermissionStatus> permissions) {
      if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      }
    });
  }
    // TODO for Real Notification Screen
  Widget showNotification() {
    return new NotificationScreen(user: widget.user);
  }

  void updateLocation() {
    Widget rv;
    bool isFabShow;
    isFabShow = true;
    rv = showNearby();
    setState((){
      this._isFabShow = isFabShow;
      this._nearBySelection = rv;
//      _pendingWidget = rv;
//      _nearBySelection = new CircularProgressIndicator();
    });
  }   

  Widget showNearby() {
    print('show Nearby ${_currentLocation}');
    Widget rv;
    if(_currentLocation != null) {
      // _pendingWidget = new TopicScreen(user: widget.user, getCurrentLocation: getCurrentLocation);
      rv = new TopicScreen(user: widget.user, getCurrentLocation: getCurrentLocation);  
    } else {
      rv = new CircularProgressIndicator();
    }
    return rv;
  }

  @override
  Widget build(BuildContext context) {
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
        case 2:      
          setState(() {
            _tabController.index = 0;
//            this._isFabShow = false;
          });
          launch(OUTLAND_SEARCH_HOST);
//          flutterWebviewPlugin.launch(OUTLAND_SEARCH_HOST, rect: Rect.fromLTWH(0.0, 0.0, MediaQuery.of(context).size.width, 300.0));
          break;
        default:
//         _nearBySelection;
          updateLocation();
      }
    });
    void sendMessageClick() {
      GeoPoint messageLocation;
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new SendTopicScreen(
                messageLocation: messageLocation, user: widget.user, isBroadcast: (_tabController.index == 1),);
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
                child: new Icon(Icons.location_city)
              ),
              new Tab(
                icon: new Icon(Icons.alarm),
              ),
              new Tab(
                icon: new Image.asset('assets/images/app-logo.png')
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
            showNotification(),
            new CircularProgressIndicator(),
            //_webView
            //_webviewPlugin,
          ],
        ),
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
