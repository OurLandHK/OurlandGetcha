import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/user_model.dart';
//import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:open_graph_parser/open_graph_parser.dart';

class TopicMessage extends StatelessWidget {
  final String messageId;
  final User user;
  GeoPoint geoTopLeft;
  GeoPoint geoBottomRight;
  final Map<String, dynamic> messageBody;
//  final Topic topic;
  final Function onTap;

  TopicMessage(
      {Key key,
  //    @required this.topic,
      @required this.messageId,
      @required this.messageBody,
      @required this.user,
      @required this.geoBottomRight,
      @required this.geoTopLeft,
      @required this.onTap})
      : super(key: key);

  bool isLink() {
    String topic = this.messageBody['topic'];
    return topic.contains("http");
  }

  Widget build(BuildContext context) {
    void _onTap() {
      if(isLink()) {
        OpenGraphParser.getOpenGraphData(this.messageBody['topic']).then((Map data) {
          this.onTap(this.messageBody['id'], data['title'], this.messageBody['imageUrl'],
              this.geoTopLeft, this.geoBottomRight);
        });
      } else {
        this.onTap(this.messageBody['id'], this.messageBody['topic'], this.messageBody['imageUrl'],
            this.geoTopLeft, this.geoBottomRight);
      }
    }

    Widget rv;
    Container messageWidget;
    //print(this.messageId);
    if(isLink()) {
      messageWidget = Container(
        child: RichLinkPreview(
            link: messageBody['topic'],
            appendToLink: true,
            backgroundColor: greyColor2,
            borderColor: greyColor2,
            textColor: Colors.black,
            launchFromLink: false),
        padding: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 10.0),
        // width: 200.0,
        //decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
        // margin: EdgeInsets.only(left: 10.0),
      );
    } else {
        messageWidget = Container(
        child: Text(
          messageBody['topic'],
            style: TextStyle(
              color: Colors.black, fontSize: 14.0, fontStyle: FontStyle.normal),
          ),
          padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
          //width: 200.0,
          //decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
          margin: EdgeInsets.only(left: 10.0),
        );         
    }
    // Time
    Container timeWidget = Container(
      child: Text(
        DateFormat('dd MMM kk:mm').format(
            new DateTime.fromMicrosecondsSinceEpoch(
                messageBody['created'].microsecondsSinceEpoch)),
        style: TextStyle(
            color: greyColor, fontSize: 12.0, fontStyle: FontStyle.italic),
      ),
      //margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
    );
    if(isLink()) {
      Widget content = new GestureDetector(onTap: _onTap, child: messageWidget);
      rv = Container(
        child: Column(
          children: <Widget>[
            content,
            timeWidget,
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    } else {
      Widget imageWidget;
      if(messageBody['imageUrl'] == null) {
        imageWidget = Column(
                children: <Widget>[
                  Material(
                    child: CachedNetworkImage(
                      placeholder: Container(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.0,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                        width: 50.0,
                        height: 50.0,
                        padding: EdgeInsets.all(15.0),
                      ),
                      imageUrl: (messageBody['createdUser'] != null) ? messageBody['createdUser']['avatarUrl'] : 'assets/images/default-avatar.jpg',
                      width: 50.0,
                      height: 50.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  Container(
                    child: Text(
                      (messageBody['createdUser'] != null) ? messageBody['createdUser']['user'] : LABEL_NOBODY,
                      style: TextStyle(color: primaryColor),
                    ),
                    alignment: Alignment.center,
                    margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                  ),
                ]
              );
      } else {
        imageWidget = Material(
                    child: CachedNetworkImage(
                      placeholder: Container(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.0,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                        width: 75.0,
                        height: 75.0,
                        padding: EdgeInsets.all(15.0),
                      ),
                      imageUrl: messageBody['imageUrl'],
                      width: 75.0,
                      height: 75.0,
                      fit: BoxFit.cover,
                    ),
//                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    clipBehavior: Clip.hardEdge,
                  );
      }
      rv = Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              imageWidget,
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      messageWidget,
                      timeWidget
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: _onTap,
          color: greyColor2,
          padding: EdgeInsets.fromLTRB(5.0, 10.0, 10.0, 5.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    }
    return rv;
  }
}
