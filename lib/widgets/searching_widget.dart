import 'package:flutter/material.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/message_service.dart';

class SearchingWidget extends StatefulWidget {
  SearchingWidget(
      {this.searchingId,
      this.searchingMsg,
      this.messageLocation,
      this.width,
      this.height,
      this.launchFromLink,
      this.vertical,
      this.user,
      this.backgroundColor,
      this.textColor});

  final String searchingId;
  final SearchingMsg searchingMsg;
  final GeoPoint messageLocation;
  final bool vertical;
  final bool launchFromLink;
  final User user;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double width;


  @override
  SearchingView createState() => SearchingView(searchingMsg);
}

// RichLinkPreviewView

class SearchingView extends SearchingModel {
  SearchingView(SearchingMsg searchingMsg): super(searchingMsg);
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            children: [Container(child: buildPreview(context))]));
  }
}

// RichLinkPreviewMode 
abstract class SearchingModel extends State<SearchingWidget>
    with TickerProviderStateMixin {
  MessageService messageService; 
  AnimationController controller;
  Animation<Offset> position;
  String _link;
  SearchingMsg _sMsg;
  SearchingModel(this._sMsg);

  void getSearchingData() async {
    messageService.getSearchMsg(widget.searchingId).then((SearchingMsg sMsg) {
      if (sMsg != null) {
        if (this.mounted) {
          setState(() {
            _sMsg = sMsg;
            _link = OURLAND_SEARCH_HOST + "/detail/" + widget.searchingId;
          });

          controller = AnimationController(
              vsync: this, duration: Duration(milliseconds: 750));
          position = Tween<Offset>(begin: Offset(0.0, 4.0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: controller, curve: Curves.bounceInOut));

          controller.forward();
        }
      } else {
        setState(() {
          _sMsg = null;
        });
      }
    });
  }

  @override
  void initState() {
    messageService = new MessageService(widget.user);
    _link = '';
    _fetchData();  
    super.initState();
  }

  void _fetchData() {
    if(this._sMsg == null) {
      getSearchingData();
    } else {
      //setState(() {
      if(_link.length != 0) {
        _link = OURLAND_SEARCH_HOST + "/detail/" + this._sMsg.key;
        controller = AnimationController(
              vsync: this, duration: Duration(milliseconds: 750));
          position = Tween<Offset>(begin: Offset(0.0, 4.0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: controller, curve: Curves.bounceInOut));

          controller.forward();
      }
      //});
    }
  }

  Widget buildPreview(BuildContext context) {
    if (_sMsg == null) {
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 8, child: _buildLoading(context)),
          ]);
    } else {
        return _buildPreviewRow(context);
    }
  }

  Widget _buildOurlandPreview(BuildContext context, SearchingMsg sMsg) {
    return Container(
        padding: const EdgeInsets.all(3.0),
//        height: _height,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
/*          border: Border(
            top: BorderSide(width: 2.0, color: _borderColor),
            left: BorderSide(width: 0.0, color: _borderColor),
            right: BorderSide(width: 2.0, color: _borderColor),
            bottom: BorderSide(width: 2.0, color: _borderColor),
          ),
          */
        ),
        child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTitle(context),
              _buildDescription(context),
            ]));
  }

  Widget _buildPreviewRow(BuildContext context) {
    if (_sMsg.thumbnailPublicImageURL != null) {
      if(widget.vertical) {
        return Container(
          
//          width: widget.width,
          child: Column(
          children: <Widget>[
                    Container(
                        child: new ClipRRect(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                            child: Image.network(_sMsg.thumbnailPublicImageURL,
//                                width: 120.0,
//                                height: _height,
//                                fit: BoxFit.fill))),
                            ))),
              _buildOurlandPreview(context, this._sMsg),
            ]
          )
        );
      } else {
        return Column(
          children: <Widget>[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                          child: new ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(3.0),
                              ),
                              child: Image.network(_sMsg.thumbnailPublicImageURL,
                                  width: 120.0,
                                  height: widget.height,
                                  fit: BoxFit.fill)))
                    ],
                  )),
              Expanded(
                  flex: 5, child: _buildOurlandPreview(context, _sMsg)),
            ]),
          ],
        );
      }
    } else {
      return _buildOurlandPreview(context, _sMsg);
/*      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[_buildOurlandPreview(context, _sMsg)],
        
      );*/
    }
  }

  Widget _buildTitle(BuildContext context) {
    if (_sMsg != null) {
      return Padding(
          padding: EdgeInsets.all(1.0),
          child: new Text(
            _sMsg.text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, color: widget.textColor),
          ));
    } else {
      return Container();
    }
  }

  Widget _buildDescription(BuildContext context) {
    if (_sMsg != null && _sMsg.desc != null &&_sMsg.desc.length > 0) {
      String desc = "";
      if(_sMsg.desc != null) {
        desc = _sMsg.desc;
      }
      return Padding(
          padding: EdgeInsets.all(2.0),
          child: new Text(desc,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: TextStyle(color: widget.textColor),
              textAlign: TextAlign.left,));
    } else {
      return Container();
    }
  }


  Widget _buildLoading(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
        ),
        child: Padding(
            padding: EdgeInsets.all(5.0),
            child: new Text("Loading",
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(color: widget.textColor))));
  }
}
