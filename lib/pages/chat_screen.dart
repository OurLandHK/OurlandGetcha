import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourland_native/models/constant.dart';
import '../models/chat_model.dart';
import './chat_map.dart';
import '../widgets/chat_message.dart';

final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final messageReference = FirebaseDatabase.instance.reference().child('messages');

class Chat extends StatelessWidget {
  final String parentId;
  final String parentTitle;

  Chat({Key key, @required this.parentId, @required this.parentTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget rv = new ChatScreen(
        parentId: this.parentId,
        parentTitle: this.parentTitle,
      );
    if(parentId.length != 0) {
      Widget rv1 = rv;
      rv = new Scaffold(
        appBar: new AppBar(
          title: new Text(
            this.parentTitle, 
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0.7,
        ),
        body: rv1,
      );
    } 
    return rv; 
  }
}

class ChatScreen extends StatefulWidget {
  final String parentId;
  final String parentTitle;

  ChatScreen({Key key, @required this.parentId, @required this.parentTitle}) : super(key: key);

  @override
  State createState() => new ChatScreenState(parentId: this.parentId, parentTitle: this.parentTitle);
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin  {
  ChatScreenState({Key key, @required this.parentId, @required this.parentTitle});

  String parentId;
  String parentTitle;
  String id;
  ChatModel chatModel;
  ChatMap chatMap;

  var listMessage;
  String groupChatId;
  SharedPreferences prefs;

  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;

  // use to get current location
  Position _currentLocation;

  StreamSubscription<Position> _positionStream;

  Geolocator _geolocator = new Geolocator();
  LocationOptions locationOptions = new LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  GeolocationStatus geolocationStatus = GeolocationStatus.denied;
  String error;

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    chatModel = new ChatModel(this.parentId);
    chatMap = null; 
    groupChatId = '';

    isLoading = false;
    isShowSticker = false;
    imageUrl = '';

    readLocal();

    initPlatformState();

    _positionStream = _geolocator.getPositionStream(locationOptions).listen(
      (Position position) {
        if(position != null) {
          setState(() {
            print('Poisition ${position}');
            _currentLocation = position;
            chatMap = new ChatMap(mapCenter: _currentLocation);
          });
        }
      });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    Position location;
    // Platform messages may fail, so we use a try/catch PlatformException.

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
        print('Location: ${location}');
        _currentLocation = location;
        chatMap = new ChatMap(mapCenter: _currentLocation);
    });

  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    if (id.hashCode <= parentId.hashCode) {
      groupChatId = '$id-$parentId';
    } else {
      groupChatId = '$parentId-$id';
    }

    setState(() {});
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();  
      chatModel.sendMessage(this._currentLocation, content, type);
      listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }


  Widget buildItem(String messageId, DocumentSnapshot document, Function _onTap) {
    Widget rv;
    rv = new ChatMessage(messageBody: document, parentId: this.parentId, messageId: messageId, onTap: _onTap);
    return rv;
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 && listMessage != null && listMessage[index - 1]['idFrom'] == id) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 && listMessage != null && listMessage[index - 1]['idFrom'] != id) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    void _onTap(String messageId, String parentTitle) {
      print("onTap");
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new Chat(parentId: messageId, parentTitle: parentTitle);
          },
        ),
      );
    }
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              new Container( 
                decoration: new BoxDecoration(
                  color: Theme.of(context).cardColor),
                child: this.chatMap,
              ),
              // List of messages
              buildListMessage(_onTap),

              // Sticker
              (isShowSticker ? buildSticker() : Container()),

              // Input content
              buildInput(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: new Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: new Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: new Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: new Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: new Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: new Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: new Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: new Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: new Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: greyColor2, width: 0.5)), color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: getImage,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.face),
                onPressed: getSticker,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: primaryColor, fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: greyColor),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: greyColor2, width: 0.5)), color: Colors.white),
    );
  }

  Widget buildListMessage(Function _onTap) {
    return Flexible(
      child: groupChatId == ''
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: this.chatModel.getMessageSnap(this._currentLocation, 1),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) => buildItem(this.parentId, snapshot.data.documents[index], _onTap),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }
}
/*

class ChatScreen extends StatefulWidget {                 
  bool root;
  ChatScreen(this.root);   
  @override                         
                      
  ChatScreenState createState() => new ChatScreenState();                    
} 

// Add the ChatScreenState class definition in main.dart.

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = <ChatMessage>[]; 
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;
                  
  @override                                                        
  Widget build(BuildContext context) {
    var rv = null;
    var rv1 = new Container(                                             //modified
      child: new Column(                                           //modified
        children: <Widget>[
            new Container( 
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor),
            child: new ChatMap(),
          ),
          new Flexible( 
            child: new ListView.builder( 
              padding: new EdgeInsets.all(8.0),
              reverse: true, 
              itemBuilder:  (BuildContext _context, int i) {
                if (i.isOdd) {
                  return const Divider();
                }
                final int index = i ~/ 2;
                return _messages[index];
              },
              itemCount: _messages.length * 2, 
            ), 
          ), 
          new Divider(height: 1.0), 
          new Container( 
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor),
            child: _buildTextComposer(), 
          ),
        ], 
      ), 
      decoration: Theme.of(context).platform == TargetPlatform.iOS 
        ? new BoxDecoration(                
            border: new Border(  
              top: new BorderSide(color: Colors.grey[200]),     
            ),                                                   
          ) 
        : null
    );
    if(!widget.root) {
      rv = new Scaffold(
        appBar: new AppBar(
          title: new Text(_app_name),
          elevation: 0.7,
        ),
        body: rv1,
      );
    } else {
      rv = rv1;
    }
    return rv; 
  }
  void _onTap() {
    print("onTap");
    Navigator.of(context).push(
      new MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return new ChatScreen(false);
        },
      ),
    );
  }


  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {  
      _isComposing = false; 
    }); 
    ChatMessage message = new ChatMessage(
      text: text, 
      animationController: new AnimationController( 
        duration: new Duration(milliseconds: 700),
        vsync: this,
      ),
      onTap: _onTap,
    );
    setState(() {
      _messages.insert(0, message);
    });

//    var _result = await messageReference.child(1)set({
//      name: 'name here',
//      message: text,
//      time : 'time here',
//      avatarUrl:'avatar here'
//    });


    message.animationController.forward();
  }

  Widget _buildTextComposer(){
    return new IconTheme(  
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(                                     //modified
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            new Flexible( 
              child: new TextField(
                controller: _textController,
                onChanged: (String text) { 
                  setState(() {   
                    _isComposing = text.length > 0; 
                  }); 
                }, 
                onSubmitted: _handleSubmitted,
                decoration: new InputDecoration.collapsed(
                  hintText: "Send a message"),
              ),
            ),
            new Container( 
              margin: new EdgeInsets.symmetric(horizontal: 4.0), 
              child: Theme.of(context).platform == TargetPlatform.iOS ? 
              new CupertinoButton(
                child: new Text("Send"),
                onPressed: _isComposing  
                    ? () =>  _handleSubmitted(_textController.text)
                    : null,) : 
              new IconButton(
                icon: new Icon(Icons.send), 
                onPressed: _isComposing
                  ? () => _handleSubmitted(_textController.text)
                  : null,
              )
            ),  
          ], 
        ),
      ),
    );
  }
  @override
  void dispose() {    
    for (ChatMessage message in _messages)  
      message.animationController.dispose(); 
    super.dispose(); 
  }   
}

@override

class ChatMessage extends StatelessWidget {
  ChatMessage({this.text, this.animationController, this.onTap});
  final String text;
  final AnimationController animationController; 
  final Function onTap;
  @override
  Widget build(BuildContext context) {
    return new SizeTransition(  
      sizeFactor: new CurvedAnimation( 
        parent: animationController, curve: Curves.easeOut), 
      axisAlignment: 0.0,  
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new GestureDetector(
          onTap: onTap,
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: new CircleAvatar(child: new Text(_user_name[0])),
              ),
              new Expanded(                                               //new
                child: new Column(                                   //modified
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(_user_name, style: Theme.of(context).textTheme.subhead),
                    new Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: new Text(text),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}

*/