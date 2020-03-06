import 'package:flutter/material.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/ranking_service.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/widgets/property_selector_widget.dart';


// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class RankingScreen extends StatefulWidget  {
  final User user;
  final Topic topic;
  final List<String> defaultProperties;
  RankingScreen({@required this.topic, @required this.user, @required this.defaultProperties});

  @override
  _RankingScreenState createState() => new _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  _RankingScreenState(
      {Key key}) {
      }
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  RankingService _rankingService;
  UserService _userService;
  MessageService _messageService;
  List<Property> _properties = [];
  List<String> _upFields = [];
  List<String> _downFields = [];
  bool _alreadyReport = true;
  Widget _optionWidget = Container();
  String _desc = "";

  @override
  void initState() {
    super.initState();
    _rankingService = new RankingService(widget.user);
    _messageService = new MessageService(widget.user);
    _userService = new UserService();
    getReportValue();
  }

  void getReportValue() {
    List<Property> properties = [];
    bool alreadyReport = true;
    // get the report value per topic
    _rankingService.getRanking(widget.topic.id).then((reports) {
      print(reports);
      if(reports != null) {
        reports.forEach((field, property) {
          print(field);
          if(field != 'recent') {
            properties.add(Property.fromMap(property));
          }
        });
      }
      String uuid = "NoBody";
      if(widget.user != null) {
        uuid = widget.user.uuid;
      }
      _rankingService.getLatestUserRanking(widget.topic.id, uuid).then((userReport) {   
        if(userReport == null) {
          alreadyReport = false;
        } else {
          if(userReport['lastUpdate'].toDate().millisecondsSinceEpoch < DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch) {
            alreadyReport = false;
          }
        }
        setState(() {
          this._properties = properties;
          this._alreadyReport = alreadyReport;
          _optionWidget = PropertySelectorWidget(widget.defaultProperties, properties, 1, [], selectField, true, true, alreadyReport || (widget.user == null), !alreadyReport &&(widget.user != null));
        });
      });
    });
  }

  void selectField(List<String> selectField, bool isUp) {
    setState(() {
      if(isUp) {
        _upFields = selectField;
        print("upfield: ${_upFields.toString()}");
      } else {
        _downFields = selectField;
        print("downfield: ${_downFields.toString()}");
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    void onSubmit() {
      // Construct ranking
      String rankingText = LABEL_RANKING_UPDATE_MESSAGE;
      if(_upFields.length > 0) {
        rankingText += "+ " + _upFields.toString() + " ";
      }
      if(_downFields.length > 0) {
        rankingText += "- " + _downFields.toString();
      }
      if(_desc.length > 0) {
        rankingText += "\n" + this._desc;
      }
      _messageService.sendChildMessage(widget.topic, null, rankingText, null, 10).then((var temp) {
        _rankingService.sendUserRankingResult(widget.topic.id, _upFields, _downFields).then((void v) {
            Navigator.of(context).pop();
        });
      });
    }
    List<Widget> widgets = [RaisedButton(
        onPressed: ((_upFields.length + _downFields.length) > 0) && !this._alreadyReport ? () => onSubmit() : null,
        child: Text(CHAT_MENU_ITEM_RANK),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue)];
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(widget.topic.topic),
      ),
      body: new Center(
        child: Container(
            child: Column(children: <Widget>[
          Text(RANK_DESC, maxLines: 3),
          //renderOption(),
          _optionWidget,
          this._alreadyReport || (widget.user == null)? Container() : TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: RANKING_LABEL_DETAIL,
            ),
            maxLines: 3,
            onChanged:  (String value) {this._desc = value;},
          ),
          (widget.user == null) ? Container() : Row(mainAxisAlignment: MainAxisAlignment.center, children: widgets)
        ])),
      ),
    );
  }
}

// ----------------------------------------
// TODO: UPDATE PROFILE IMAGE SCREEN
// ----------------------------------------
