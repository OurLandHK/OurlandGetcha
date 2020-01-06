import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/services/message_service.dart';
//import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/widgets/searching_widget.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:geodesy/geodesy.dart';

class SearchingMsgWidget extends StatelessWidget {
  final SearchingMsg searchingMsg;
  final User user;
  final Function getCurrentLocation;
  final GeoPoint messageLocation;
  final bool locationPermissionGranted;

  SearchingMsgWidget(
      {Key key,
      @required this.searchingMsg,
      @required this.user,
      @required this.getCurrentLocation,
      @required this.locationPermissionGranted,
      @required this.messageLocation})
      : super(key: key);

  Widget build(BuildContext context) {
    if(this.searchingMsg == null) {
      print("this.searchingMsg == null");
      return Container();
    }

    void __onTap(Topic topic, String parentTitle, GeoPoint messageLocation) async {
      //GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      GeoPoint _messageLocation = messageLocation;
  /*
      if(_messageLocation == null && this.fixLocation != null) {
        _messageLocation = this.fixLocation;
      } 
  */    
      if(_messageLocation == null && this.messageLocation != null) {
        _messageLocation = new GeoPoint(this.messageLocation.latitude, this.messageLocation.longitude);
      }
      bool enableSendButton = false;
      // Check for previous edit topic
      if(this.user != null) {
        UserService userService = new UserService();
        RecentTopic recentTopic = await userService.getRecentTopic(this.user.uuid, topic.id);
        if(recentTopic != null) {
          //print("Recent Topic");
          _messageLocation = recentTopic.messageLocation;
          enableSendButton = true;
        } else {
          if(user.homeAddress != null) {
            //print("Home");
            enableSendButton = topic.searchingMsg.isAddressWithin(user.homeAddress);
          }
          if(!enableSendButton && user.officeAddress != null) {
            //print("Office");
            enableSendButton = topic.searchingMsg.isAddressWithin(user.officeAddress);
          }
          if(!enableSendButton && locationPermissionGranted) {
            print("Current");
            Map map = getCurrentLocation();
            GeoPoint mapCenter = map['GeoPoint'];
            enableSendButton = topic.searchingMsg.isAddressWithin(mapCenter);
          }
        }
      } 
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            Key chatKey = new Key(topic.id);
            return ChatScreen(/*key: chatKey,*/ user : user, topic: topic,  parentTitle: parentTitle, messageLocation: _messageLocation);
          },
        ),
      );
    }
    //String title = this.searchingMsg.text;
    void _onTap() {
      MessageService messageService = new MessageService(this.user);
      messageService.getTopic(this.searchingMsg.key).then((topic) {
        if(topic == null) {
          topic = Topic.fromSearchingMsg(this.searchingMsg);
        } else {
          topic.searchingMsg = this.searchingMsg;
        }
        //return this.onTap(topic, searchingMsg.text, this.messageLocation);
        return __onTap(topic, searchingMsg.text, this.messageLocation);
      });
    }

    Widget rv = new Container();
    if(this.searchingMsg != null) {
      Widget messageWidget = SearchingWidget(
          searchingId: this.searchingMsg.key,
          searchingMsg: this.searchingMsg,
          messageLocation: this.messageLocation,
          vertical: false,
          launchFromLink: false,
          user: user,
          backgroundColor: TOPIC_COLORS[this.searchingMsg.key.hashCode % TOPIC_COLORS.length],
          textColor: Colors.black
      );

      List<Widget> footers = []; 
    
      for(int i = 0; i< this.searchingMsg.tagfilter.length && i < 3 ; i++) {
  //      footers.add(Chip(label: Text(this.topic.tags[i], style: Theme.of(context).textTheme.subtitle), backgroundColor: TOPIC_COLORS_DARKER[this.topic.color]));
        footers.add(Text("#${this.searchingMsg.tagfilter[i]}", style: Theme.of(context).textTheme.subtitle));

      }
        
      // Time
      Container timeWidget = Container(
        child: Text(
          DateFormat('dd MMM kk:mm').format(
              new DateTime.fromMicrosecondsSinceEpoch(
                this.searchingMsg.lastUpdate.microsecondsSinceEpoch)),
          style: Theme.of(context).textTheme.subtitle),
      );
      // Distance
      Container distanceWidget = Container(
        child: Text(
                "  ${this.searchingMsg.distance}km",
          style: Theme.of(context).textTheme.subtitle),
      );
      footers.add(Expanded(flex: 1, child: Container()));
      footers.add(timeWidget);
      footers.add(distanceWidget); 
      
      List<Widget> topicColumn = [Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: messageWidget,
                          ),
                        ),
                      ],
                    )];
      topicColumn.add(Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: footers));
      rv = GestureDetector(
          onTap: _onTap,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              padding: EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: TOPIC_COLORS[this.searchingMsg.key.hashCode % TOPIC_COLORS.length],
                border: Border.all(width: 1, color: Colors.grey),
                boxShadow: [
                  new BoxShadow(
                    color: Colors.grey,
                    offset: new Offset(0.0, 2.5),
                    blurRadius: 4.0,
                    spreadRadius: 0.0
                  )
                ],
                //borderRadius: BorderRadius.circular(6.0)
                ),
              child: Column(
                children: topicColumn,
              ),
            ),
          ),
        );
    }
    return rv;
  }  
}
