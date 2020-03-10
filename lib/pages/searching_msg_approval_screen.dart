import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:ourland_native/widgets/chat_list.dart';
import 'package:ourland_native/widgets/chat_popup_menu.dart';
import 'package:ourland_native/widgets/chat_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ourland_native/services/user_service.dart';

import '../models/chat_model.dart';
import '../widgets/send_message.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class SearchingMsgApprovalScreen extends StatelessWidget {
  final SearchingMsg searchingMsg;
  final SharedPreferences preferences;
  final User user;
  SearchingMsgApprovalScreen({Key key, @required this.preferences, @required this.user, @required this.searchingMsg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
          key: _scaffoldKey,
          appBar: new AppBar(
            title: new Text(
              this.searchingMsg.text,
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            actions: this.user != null ? <Widget>[
              new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
              ),
              /*new ChatPopupMenu(this.topic, this.user)*/
            ] : null,
            centerTitle: true,
            elevation: 0.7,
          ),
          body: Container(
            //color: TOPIC_COLORS[topic.color],
            child: SearchingMsgApprovalScreenBody(
              user: this.user,
              preferences: preferences,
              searchingMsg: this.searchingMsg,

            ),
          ),
        );
  }
}

class SearchingMsgApprovalScreenBody extends StatefulWidget {
  SearchingMsg searchingMsg;
  final SharedPreferences preferences;
  final User user;

  SearchingMsgApprovalScreenBody({Key key, @required this.preferences, @required this.user, @required this.searchingMsg}) : super(key: key);

  @override
  State createState() => new SearchingMsgApprovalBodyState();
}

class SearchingMsgApprovalBodyState extends State<SearchingMsgApprovalScreenBody> with TickerProviderStateMixin  {
  MessageService messageService;
  UserService _userService;

  final TextEditingController textEditingController = new TextEditingController();

  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();
  SearchingMsgApprovalBodyState({Key key});
  bool isLoading = true;
 
  void approveMessage() {
    messageService.approveSearchingMessage(widget.searchingMsg);
  }

  void rejectMessage() {
    messageService.rejectSearchingMessage(widget.searchingMsg);
  }
  @override
  Widget build(BuildContext context) {
    Topic topic = Topic.fromSearchingMsg(widget.searchingMsg);
    ValueNotifier<GeoPoint> summaryTopLeft = new ValueNotifier<GeoPoint>(topic.geoTopLeft);
    ValueNotifier<GeoPoint> summaryBottomRight = new ValueNotifier<GeoPoint>(topic.geoBottomRight);
    RaisedButton approveButton = RaisedButton(
              child: Text(LABEL_APPROVE),
              onPressed: approveMessage,
            );
    RaisedButton rejectButton = RaisedButton(
              child: Text(LABEL_REJECT),
              onPressed: rejectMessage,
            );        
    ChatSummary chatSummary = ChatSummary(preferences: widget.preferences, topLeft: summaryTopLeft, bottomRight: summaryBottomRight, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height/4, user: widget.user, imageUrl: topic.imageUrl, topic: topic, messageLocation: topic.geoCenter, chatMode: Chat_Mode.APPROVE_MODE, toggleComment: null, updateUser: null, getUserName: null, getAllUserList: null, getColor: null);
    List<Widget> buttonList = [];
    if(widget.user != null && (widget.user.globalHideRight || widget.user.uuid == widget.searchingMsg.uid)) {
      buttonList.add(rejectButton);
    }
    if(widget.user != null && widget.user.globalHideRight) {
      buttonList.add(approveButton);
    }
    ButtonBar bar = ButtonBar(children: buttonList);
    List<Widget> _widgetList = [chatSummary, bar];
    Widget _bodyWidget =  Column(children: _widgetList);
    _bodyWidget = SingleChildScrollView(child: _bodyWidget);
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          _bodyWidget,
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
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

  @override
  void initState() {
    _userService = new UserService();
    super.initState();
    focusNode.addListener(onFocusChange);
    messageService = new MessageService(widget.user);
    isLoading = false;    
  }

  Future<bool> onBackPress() {
    Navigator.pop(context);
    return Future.value(false);
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
      });
    }
  }  
}
