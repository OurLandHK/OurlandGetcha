import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as Img;

import 'package:image_picker/image_picker.dart';
//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/services/user_service.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final messageReference = FirebaseDatabase.instance.reference().child('messages');
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class SendMessage extends StatefulWidget {
  final MessageService messageService;
  final GeoPoint messageLocation;
  final ScrollController listScrollController;
  final String parentID;

  SendMessage({Key key, @required this.parentID, @required this.messageService, @required this.messageLocation, @required this.listScrollController}) : super(key: key);

  @override
  State createState() => new SendMessageState(messageService: this.messageService, messageLocation: this.messageLocation, listScrollController: this.listScrollController);
}

class SendMessageState extends State<SendMessage> with TickerProviderStateMixin  {
  MessageService messageService;
  GeoPoint messageLocation;
  ScrollController listScrollController;
  UserService userService;

  SendMessageState({Key key, @required this.messageService, @required this.messageLocation, @required this.listScrollController}) {
    print('SendMessageState ${this.messageLocation}');
  }

  SharedPreferences prefs;

  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;
  String error;

  final TextEditingController textEditingController = new TextEditingController();
  
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    userService = new UserService();
    isLoading = false;
    isShowSticker = false;
    imageUrl = '';
  }


  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  Future getImageFromGallery() async {
    await getImage(ImageSource.gallery);
  }

  Future getImageFromCamera() async {
    await getImage(ImageSource.camera);
  }

  Future getImage(ImageSource imageSource) async {
    File newImageFile = await ImagePicker.pickImage(source: imageSource);

    if (newImageFile != null) {
      setState(() {
        imageFile = newImageFile;
        print("${imageFile.uri.toString()}");
      });
    }
  }
/*
  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }
*/
  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }
/*
  Future uploadFile() async {
    File uploadImage = imageFile;
    List<int> blob = uploadImage.readAsBytesSync();
    
    Img.Image originImage = Img.decodeImage(blob);
    Img.Image image = originImage;

    bool newImage = false;
    if(originImage.width > 1280) {
      image = Img.copyResize(originImage, 1280);
      newImage = true;
    } else {
      if(originImage.height > 1280) {
        int width = (originImage.width * 1280 / originImage.height).round();
        image = Img.copyResize(originImage, width, 1280);  
        newImage = true;     
      }
    }

    if(newImage) {
  //    uploadImage = new File('temp.png').writeAsBytesSync(Img.encodePng(image));
//      blob = new Img.PngEncoder({level: 3}).encodeImage(image);
      blob = new Img.JpegEncoder(quality: 75).encodeImage(image);
    }
    String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putData(blob);
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
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(CHAT_FILE_NOT_IMG)));
    });
  }
*/
  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();  
      messageService.sendChildMessage(widget.parentID, this.messageLocation, content, imageFile, type).then((void v) {
        userService.addRecentTopic(messageService.user.uuid, widget.parentID, this.messageLocation).then((var user) {
          setState(( ){
            imageFile = null;
          });
        });
      });
      listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(CHAT_NTH_TO_SEND)));
    }
  }
  // TODO handle BackPress to dismiss sticker
/*
  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } 
    return Future.value(false);
  }
*/
  void removeImage() {setState((){imageFile = null;});}

  Widget buildImagePreview() {
    return Container(
      child:  Stack(children: [Image.file(
            imageFile, height: 180.0
          ), IconButton(icon: Icon(Icons.close), onPressed: removeImage,)]),
      decoration: new BoxDecoration(
        border: new Border(top: new BorderSide(color: greyColor2, width: 0.5)), color: greyColor2),
      padding: EdgeInsets.all(5.0),
      height: 181.0,
    );
  }
/*
  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: new Image.asset(
                  'assets/images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: new Image.asset(
                  'assets/images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: new Image.asset(
                  'assets/images/mimi3.gif',
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
                  'assets/images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: new Image.asset(
                  'assets/images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: new Image.asset(
                  'assets/images/mimi6.gif',
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
                  'assets/images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: new Image.asset(
                  'assets/images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: new Image.asset(
                  'assets/images/mimi9.gif',
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
*/
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[              // Sticker
//        (isShowSticker ? buildSticker() : Container()),
        imageFile != null ? buildImagePreview() : new Container(),
        Container(
          child: Row(
            children: <Widget>[
              // Button send image
              /*
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
              */
              Material(
                child: new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 1.0),
                  child: new IconButton(
                    icon: new Icon(Icons.image),
                    onPressed: getImageFromGallery,
                    color: primaryColor,
                  ),
                ),
              ),
              Material(
                child: new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 1.0),
                  child: new IconButton(
                    icon: new Icon(Icons.camera_enhance),
                    onPressed: getImageFromCamera,
                    color: primaryColor,
                  ),
                ),
              ),
              // Remove Sticker temporary
              /*
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
              */
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
        )
      ]
    );
  }
}
