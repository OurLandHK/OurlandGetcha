
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_model.dart';
import './chat_map.dart';

const String _user_name = "Your name";
const String _app_name = "我地.佳招";

final facebookLogin = new FacebookLogin();
final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final reference = FirebaseDatabase.instance.reference().child('messages');



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
