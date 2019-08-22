import 'package:flutter/material.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/widgets/image_widget.dart';
import 'package:ourland_native/services/message_service.dart';

class SearchingWidget extends StatefulWidget {
  SearchingWidget(
      {this.searchingId,
      this.messageLocation,
      this.width,
      this.height,
      this.launchFromLink,
      this.vertical,
      this.user,
      this.backgroundColor,
      this.textColor});

  final String searchingId;
  final GeoPoint messageLocation;
  final bool vertical;
  final bool launchFromLink;
  final User user;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double width;


  @override
  SearchingView createState() => SearchingView();
}

// RichLinkPreviewView

class SearchingView extends SearchingModel {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            children: [Container(child: buildRichLinkPreview(context))]));
  }
}

// RichLinkPreviewMode 
abstract class SearchingModel extends State<SearchingWidget>
    with TickerProviderStateMixin {
  MessageService messageService; 
  AnimationController controller;
  Animation<Offset> position;
  String _link;
  /*
  double _height;
  double _width;
  Color _borderColor;
  Color _backgroundColor;
  Color _textColor;
  bool _appendToLink;
  bool _isLink;
  bool _launchFromLink;
  bool _vertical;
  Map _ogData;*/
  SearchingMsg _sMsg;

  void getSearchingData() async {
    messageService.getSearchMsg(widget.searchingId).then((SearchingMsg sMsg) {
      if (sMsg != null) {
        if (this.mounted) {
          setState(() {
            _sMsg = sMsg;
            _link = OUTLAND_SEARCH_HOST + "/detail/" + widget.searchingId;
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
  /*  
    _link = widget.link ?? '';
    _height = widget.height ?? 100.0;
    _width = widget.width ?? 200.0;
    _borderColor = widget.borderColor ?? Color(0xFFE0E0E0);
    _textColor = widget.textColor ?? Color(0xFF000000);
    _backgroundColor = widget.backgroundColor ?? Color(0xFFE0E0E0);
    _appendToLink = widget.appendToLink ?? false;
    _launchFromLink = widget.launchFromLink ?? true;
    _vertical = widget.vertical ?? false;
  */
    _fetchData();  
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool isValidUrl(link) {
    String regexSource =
        "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]";
    final regex = RegExp(regexSource);
    final matches = regex.allMatches(link);
    for (Match match in matches) {
      if (match.start == 0 && match.end == link.length) {
        return true;
      }
    }
    return false;
  }

  @override
  void didUpdateWidget(SearchingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    /*
    if (this.mounted && _appendToLink == false) {
      setState(() {
        _link = oldWidget.link != widget.link ? widget.link : '';
      });
    }
    */
    _fetchData();
  }

  void _fetchData() {
    getSearchingData();
    /*
    if (isValidUrl(_link) == true) {
      getSearchingData();
      _isLink = true;
    } else {
      if (this.mounted) {
        setState(() {
          _ogData = null;
        });
      }
      _isLink = false;
    }
    */
  }

  void _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget buildRichLinkPreview(BuildContext context) {
    if (_sMsg == null) {
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 8, child: _buildUrl(context)),
          ]);
    } else {
//      if (_appendToLink == true) {
        return _buildWrappedInkWell(_buildPreviewRow(context));
        /*
      } else {
        return (SlideTransition(
            position: position,
            child: Container(
                height: _height,
                decoration: new BoxDecoration(
                  borderRadius:
                      const BorderRadius.all(const Radius.circular(8.0)),
                ),
                child: _buildPreviewRow(context))));
      }
      */
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
          
          width: widget.width,
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
              //_buildUrl(context),
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Expanded(flex: 8, child: _buildUrl(context)),
            ])
          ],
        );
      }
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[_buildOurlandPreview(context, _sMsg)],
      );
    }
  }

  Widget _buildTitle(BuildContext context) {
    if (_sMsg != null) {
      return Padding(
          padding: EdgeInsets.all(1.0),
          child: new Text(
            _sMsg.text,
            overflow: TextOverflow.ellipsis,
            //style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
          ));
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildDescription(BuildContext context) {
    if (_sMsg != null) {
      return Padding(
          padding: EdgeInsets.all(2.0),
          child: new Text(_sMsg.desc,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: TextStyle(color: widget.textColor)));
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildUrl(BuildContext context) {
    if (_link != '' /*&& _appendToLink == true*/) {
      return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
          ),
          child: Padding(
              padding: EdgeInsets.all(5.0),
              child: new Text(_link,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(color: widget.textColor))));
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildWrappedInkWell(Widget widget) {
    if (_link != '' && this.widget.launchFromLink) {
      return InkWell(child: widget, onTap: () => _launchURL(_link));
    }
    return widget;
  }
}
