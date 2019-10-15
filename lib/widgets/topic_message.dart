import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:ourland_native/widgets/rich_link_preview.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/widgets/base_profile.dart';
import 'package:ourland_native/widgets/image_widget.dart';
//import 'package:open_graph_parser/open_graph_parser.dart';
import 'package:ourland_native/helper/open_graph_parser.dart';
import 'package:ourland_native/widgets/searching_widget.dart';

class TopicMessage extends StatelessWidget {
  final Topic topic;
  final User user;
  final Function onTap;
  final GeoPoint messageLocation;

  TopicMessage(
      {Key key,
      @required this.topic,
      @required this.user,
      @required this.onTap,
      @required this.messageLocation})
      : super(key: key);

  bool isLink() {
    if(this.topic != null) {
      String title = this.topic.topic;
      return title.contains("http");
    } else {
      return false;
    }
  }
  Widget build(BuildContext context) {
    if(this.topic == null) {
      return Container();
    }
    String topicTitle = this.topic.topic;
    void _onTap() {
      if(isLink()) {
        OpenGraphParser.getOpenGraphData(this.topic.topic).then((Map data) {
          topicTitle = data['title'];
          this.onTap(this.topic, data['title'], this.messageLocation);
        });
      } else {
        this.onTap(this.topic, this.topic.topic, this.messageLocation);
      }
    }

    Widget rv = new Container();
    if(this.topic != null) {
      Container messageWidget;
      //print(this.messageId);
      if(this.topic.searchingId != null) {
        //print("searching id ${this.topic.searchingId}");
        messageWidget = Container(
          child: SearchingWidget(
            searchingId: this.topic.searchingId,
            searchingMsg: null,
            messageLocation: this.messageLocation,
            vertical: true,
            launchFromLink: false,
            user: user,
            backgroundColor: TOPIC_COLORS[topic.color],
            textColor: Colors.black,
          )
        );
      } else {
        if(isLink() && this.topic.imageUrl == null) {
          // Display Ourland Search
          messageWidget = Container(
            child: RichLinkPreview(
                link: this.topic.topic,
                appendToLink: true,
                backgroundColor: TOPIC_COLORS[topic.color],
                borderColor: greyColor2,
                textColor: Colors.black,
                width: MediaQuery.of(context).size.width * 0.45,
                launchFromLink: false,
                vertical: true),
            padding: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 10.0),
          );
        } else {
            messageWidget = Container(child:Text(
                                  topicTitle,
                                  style: Theme.of(context).textTheme.body1,
                                )
            );
        }
      }
    List<Widget> footers = [];
    List<Widget> tags = [];  
    // tag
    String tagText ="";
    for(int i = 0; i< this.topic.tags.length; i++) {
      tagText += "#"+this.topic.tags[i];
    }
    if(tagText.length > 0) {
      tags.add(Text(tagText, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.subtitle));
    }
        
        
    // Time
    Container timeWidget = Container(
      child: Text(
        DateFormat('dd MMM kk:mm').format(
            new DateTime.fromMicrosecondsSinceEpoch(
              this.topic.lastUpdate.microsecondsSinceEpoch)),
        style: Theme.of(context).textTheme.subtitle),
    );
    footers.add(Expanded(flex: 1, child: Container()));
    footers.add(timeWidget);
      
    if(this.topic.imageUrl != null && this.topic.searchingId == null) {
      Widget imageWidget;
      imageWidget = new ImageWidget(height: null, width: MediaQuery.of(context).size.width * 0.45, imageUrl: this.topic.imageUrl); 
      messageWidget = Container(child: new Column(children: <Widget>[imageWidget, messageWidget]));
    }
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
    if(this.topic.searchingId == null && this.topic.content != null && this.topic.content.length > 0) {
      String content = this.topic.content;
      topicColumn.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                    content,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.body2),
              )],),));
    }
    topicColumn.add(Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: tags));
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
                color: TOPIC_COLORS[topic.color],
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
