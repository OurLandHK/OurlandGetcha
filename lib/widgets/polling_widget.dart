import 'package:flutter/material.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/polling_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/widgets/image_widget.dart';
import 'package:ourland_native/services/polling_service.dart';

class PollingWidget extends StatefulWidget {
  PollingWidget(
      {this.searchingMsg,
      this.messageLocation,
      this.width,
      this.height,
      this.user,
      this.darkBackgroundColor,
      this.backgroundColor,
      this.textColor});

  final SearchingMsg searchingMsg;
  final GeoPoint messageLocation;
  final User user;
  final Color darkBackgroundColor;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double width;


  @override
  PollingView createState() => PollingView(searchingMsg , searchingMsg.key);
}


class PollingView extends PollingModel {
  PollingView(SearchingMsg searchingMsg, String pollingKey): super(searchingMsg, pollingKey);
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            children: [Container(child: buildPreview(context))]));
  }
}

// RichLinkPreviewMode 
abstract class PollingModel extends State<PollingWidget>
    with TickerProviderStateMixin {
  PollingService pollingService; 
  AnimationController controller;
  Animation<Offset> position;
  SearchingMsg _sMsg;
  String _pollingKey;
  List<int> _upvote;
  int _totalUpvote = 0;
  int _resultTotalUpvote = 0;
  bool _loading = false;
  Polling _polling;
  PollingResult _result;
  PollingResult _userResult;
  PollingModel(this._sMsg, this._pollingKey) {
    _polling = _sMsg.polling;
  }

  void getPollingData() async {
    pollingService.getUserResult(_sMsg.key, widget.user.uuid).then((PollingResult userResult) {
      pollingService.getResult(_sMsg.key).then((result) {
        if(userResult != null) {
          setState(() {
            _userResult = userResult;
            _result = result;
            _upvote = userResult.upvote;
            _loading = false;
          });
          
        }
      });
    });
  }

  @override
  void initState() {
    pollingService = new PollingService(widget.user);
    _upvote = new List<int>(_sMsg.polling.pollingOptionValues.length);
    for(int i = 0; i< _upvote.length; i++) {
      _upvote[i] = 0;
    }
    _fetchData();  
    super.initState();
  }


  void _fetchData() {
    if(this._userResult == null) {
      getPollingData();
    } else {
      setState(() {
      controller = AnimationController(
            vsync: this, duration: Duration(milliseconds: 750));
        position = Tween<Offset>(begin: Offset(0.0, 4.0), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: controller, curve: Curves.bounceInOut));

        controller.forward();
      });
    }
  }

  Widget buildPreview(BuildContext context) {
    if (_loading) {
      print("buildRichLinkPreview _sMsg == null"); 
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 8, child: _buildLoading(context)),
          ]);
    } else {
        if(_sMsg.status == SEARCHING_STATUS_OPTIONS[1] || _userResult != null) {
          return _buildPollingPreview(context, true);
        } else {
          return _buildPollingPreview(context, false);
        }
    }
  }


  Widget _buildPollingPreview(BuildContext context, bool displayResult) {
    Color _borderColor =  widget.textColor;
    return Container(
        padding: const EdgeInsets.all(3.0),
//        height: _height,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
            border: Border(
            top: BorderSide(width: 2.0, color: _borderColor),
            left: BorderSide(width: 0.0, color: _borderColor),
            right: BorderSide(width: 2.0, color: _borderColor),
            bottom: BorderSide(width: 2.0, color: _borderColor),
          ),
          
        ),
        child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTitle(context),
              _buildOptions(context, displayResult),
            ]));
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(1.0),
        child: new Text(
          _sMsg.polling.pollingTitle,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, color: widget.textColor),
        ));
  }

  void _onTap(int i, bool displayResult) {
    if(!displayResult ){
      if(_upvote[i] == 0) {
        if(_totalUpvote < _polling.numOfMaxPolling) {
          setState(() {
            _upvote[i] = 1;
            _totalUpvote++;
          });
        }
      } else {
        setState(() {
          _upvote[i] = 0;
          _totalUpvote--;
        });
      }
    }
  }

  Future<void> vote() async {
    setState(() {
      _loading = true;
    });
    _userResult = new PollingResult(_upvote);
    pollingService.sendUserPollingResult(_sMsg.key, _userResult).then((temp) {
      return getPollingData();
    });
  }

  Widget _buildOptions(BuildContext context, bool displayResult) {
    List<Widget> listOfWidget = [];
    double optionWidth = MediaQuery.of(context).size.width;
    String desc1 = LABEL_VOTE_RANGE + " " + _sMsg.polling.pollingRange.toString() + LABEL_KM;
    String desc2 = LABEL_VOTE_MAX +_sMsg.polling.numOfMaxPolling.toString();
    Text descText1 = new Text(desc1,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            style: TextStyle(color: widget.textColor),
            textAlign: TextAlign.center);
    Text descText2 = new Text(desc2,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            style: TextStyle(color: widget.textColor),
            textAlign: TextAlign.center);
    listOfWidget.add(Row(children:[descText1, Flexible(flex: 1, child: Container()), descText2]));
    int totalUpvote = 0;
    if(displayResult) {
      for(int i = 0; i < _result.upvote.length; i++) {
        totalUpvote += _result.upvote[i];
      }
    }
    for(int i = 0; i < _sMsg.polling.pollingOptionValues.length; i++) {
      int upvoteResult = 0;
      if(displayResult) {
        upvoteResult = _result.upvote[i];
      }
      Color color = widget.backgroundColor;
      if(_upvote[i] == 1) {
        color = widget.textColor;
      }
      String resultText =  displayResult ? upvoteResult.toString() : " " ;
      Widget textWidget = Text(_sMsg.polling.pollingOptionValues[i]);
      if(displayResult) {
        textWidget = Row(children: [
          textWidget,
          Flexible(flex: 1,child: Container()),
          Text(resultText),
        ]);
      }
      Widget optionBox = SizedBox(
                  width: optionWidth,
                  child: FlatButton(
                  child: textWidget, 
                  onPressed: () => {_onTap(i, displayResult)}
                  )
                );
                print("${_upvote[i]}");
      LinearGradient gradient;
      if(displayResult) {
        gradient = LinearGradient(colors: [widget.darkBackgroundColor , Colors.white],
                        stops: [upvoteResult / totalUpvote, upvoteResult / totalUpvote],
                        tileMode: TileMode.clamp);
      }
      optionBox = Container(
                      decoration: new BoxDecoration(
                        gradient: gradient,
                        border: Border.all(
                          color: color,
                          width: 1.2,
                        ),
                      ),
                      child: optionBox
        );
      listOfWidget.add(optionBox);
    }
    if(!displayResult) {
      listOfWidget.add(FlatButton(child: Text(LABEL_VOTE), onPressed: vote));
    } else {
      listOfWidget.add(FlatButton(child: Text(LABEL_VOTED + _userResult.lastUpdate.toString())));
    }
    return Column (children: listOfWidget);
    
  }


  Widget _buildLoading(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
        ),
        child: Padding(
            padding: EdgeInsets.all(5.0),
            child: new Text('等一下',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(color: widget.textColor))));
  }
}
