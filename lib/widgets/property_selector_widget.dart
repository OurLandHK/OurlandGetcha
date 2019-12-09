import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/constant.dart';

class Property {
  String _field;
  int _value;
  int _downValue;
  DateTime _lastUpdate;

  Property(this._field, this._value) {
    _lastUpdate = DateTime.now();
  }

  int get value => this._value;
  int get downValue => this._downValue;
  DateTime get lastUpdate => this._lastUpdate;
  String get propertyField => this._field;

  void updateValue(int value) {
    _value = value;
    _lastUpdate = DateTime.now();
  }

  void updateDownValue(int downValue) {
    _downValue = downValue;
    _lastUpdate = DateTime.now();
  }

  Property.fromMap(Map map) {
    if(map['lastUpdate'] != null) {
      this._lastUpdate = DateTime.fromMicrosecondsSinceEpoch(map['lastUpdate'].microsecondsSinceEpoch);
    }
    this._value = map['value'];
    if(map['downValue'] != null ) {
      this._downValue = map['downValue'];
    }
    this._field = map['field'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['lastUpdate'] = _lastUpdate;
    map['value'] = _value;
    if(this._downValue != null) {
      map['downValue'] = this._downValue;
    }
    map['field'] = _field;
    return map;
  }
}


class PropertySelectorWidget extends StatefulWidget {
  PropertySelectorWidget(
      @required this.defaultFields, 
      @required this.currentProperties, 
      @required this.totalSelect,
      @required this.currentSelectProperties,
      this.showLastUpdate,
      this.updownProperty,
      this.readOnly);


  final List<String> defaultFields;
  final List<Property> currentProperties;
  final Function currentSelectProperties;
  final int totalSelect;
  bool showLastUpdate = false;
  bool readOnly = true;
  bool updownProperty = false;

  @override
  PropertySelectorView createState() => PropertySelectorView();
}


class PropertySelectorView extends PropertySelectorModel {
  PropertySelectorView(): super();
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            children: [Container(child: buildOptions(context, true))]));
  }
}

// RichLinkPreviewMode 
abstract class PropertySelectorModel extends State<PropertySelectorWidget>
    with TickerProviderStateMixin {
  List<String> selectedFields = [];
  List<String> selectedDownFields = [];
  Map<String, Property> _currentPropertiesMap;
  PropertySelectorModel() {
  }

  @override
  void initState() {
    _currentPropertiesMap = new Map();
    //print("Current Properties ${widget.currentProperties.length}");
    for(int i = 0; i< widget.currentProperties.length; i++) {
      String field = widget.currentProperties[i].propertyField;
      print("field ${field} ${widget.currentProperties[i].value}");
      _currentPropertiesMap[field] =  widget.currentProperties[i];
    }
    for(int i = 0; i< widget.defaultFields.length; i++) {
      String field = widget.defaultFields[i];
      if(_currentPropertiesMap[field] == null) {
        _currentPropertiesMap[field] = new Property(field, 0);
      }
    }
    super.initState();
  }

  void _onTap(field) {
    setState(() {
      if(selectedFields.remove(field)) {
        selectedFields.join(', ');
      } else {
        if(selectedFields.length + selectedDownFields.length < widget.totalSelect) {
          selectedFields.add(field);
        }
      }      
    });
    widget.currentSelectProperties(selectedFields);
  }

  void _onTapDown(field) {
    setState(() {
      if(selectedDownFields.remove(field)) {
        selectedDownFields.join(', ');
      } else {
        if(selectedDownFields.length + selectedFields.length< widget.totalSelect) {
          selectedDownFields.add(field);
        }
      }      
    });
    widget.currentSelectProperties(selectedDownFields);
  }

  Widget buildOptions(BuildContext context, bool displayResult) {
    List<Widget> listOfWidget = [];
    double optionWidth = MediaQuery.of(context).size.width;
    _currentPropertiesMap.forEach((field, property) {
      double borderSize = 1.2;
      Color boxColor = Theme.of(context).dialogBackgroundColor;
      Color leftButtonColor = Theme.of(context).dialogBackgroundColor;
      Color rightButtonColor = Theme.of(context).dialogBackgroundColor;
      String resultText = "";
      String fieldText = field;
      Widget textWidget = Text(fieldText);
      int value = property.value;
      int downValue = property.downValue;
      double optionBoxWidth = optionWidth;
      String lastUpdateText = LABEL_LAST_UPDATE + DateFormat('dd MMM kk:mm').format(
                new DateTime.fromMicrosecondsSinceEpoch(
                  property._lastUpdate.microsecondsSinceEpoch));
      LinearGradient gradient;
      if(selectedFields.contains(field)) {
        value++;
        borderSize = 2;
        boxColor = Theme.of(context).accentColor;
        rightButtonColor = Colors.yellow;
      }
      if(widget.updownProperty) {
        if(!widget.readOnly) {
          optionBoxWidth -= 120;
        }
        if(downValue == null) {
          downValue = 0;
        }
        if(selectedDownFields.contains(field)) {
          downValue++;
          borderSize = 2;
          leftButtonColor = Colors.blue;
        }
        int totalVote = downValue + value;
        if(displayResult && totalVote > 0) {    
          gradient = LinearGradient(colors: [Colors.yellow , Colors.blue],
              stops: [value / totalVote, value / totalVote],
              tileMode: TileMode.clamp);
        }
        if(widget.showLastUpdate && property._lastUpdate != null) {
          resultText += lastUpdateText;
          textWidget = Column(children: [
            textWidget,
            Text(lastUpdateText ,style: Theme.of(context).textTheme.subtitle),
          ]);
        }
        String valueText = "";
        String valueDownText = "";
        if(displayResult) {
          valueText = " " + value.toString();
          valueDownText = " " + downValue.toString() + " ";
        }        
        textWidget = Row(children: [
          Text(valueText),
          Flexible(flex: 2,child: Container()),
          textWidget,
          Flexible(flex: 2,child: Container()),
          Text(valueDownText),
        ]);           
      } else {
        if(widget.showLastUpdate && property._lastUpdate != null) {
          resultText += lastUpdateText;
        }
        if(displayResult) {
          resultText += "   " + value.toString();
        }
        textWidget = Row(children: [
          textWidget,
          Flexible(flex: 2,child: Container()),
          Text(resultText),
        ]);
      }
      Widget optionBox = SizedBox(
          width: optionBoxWidth,
          child: Container(
            decoration: new BoxDecoration(
              gradient: gradient,
              color: boxColor,
            ),
            child: FlatButton(
              child: textWidget, 
              onPressed: widget.readOnly ? null : () => {_onTap(field)}
            )
          )
        );

      /*
                //print("${_upvote[i]}");
      optionBox = Container(
                      decoration: new BoxDecoration(
                        gradient: gradient,
                        color: boxColor,
                      ),
                      child: optionBox
        );
      */
      if(widget.updownProperty && !widget.readOnly) {
        optionBox = Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          SizedBox(
            width: 40,
            child: RaisedButton(
              color: leftButtonColor,
              onPressed: (widget.readOnly) ? null : () => {_onTapDown(field)},
              child: Text("-",textAlign: TextAlign.center,))),
          
          /*
          SizedBox(
            width: 25,
            child: IconButton(
            icon: Icon(Icons.arrow_left),
            //color: Colors.blue,
            onPressed: (widget.readOnly) ? null : () => {_onTapDown(field)}
            )),
          */
          Container(),
          optionBox,
          Container(),
          SizedBox(
            width: 40,
            child: RaisedButton(
              color: rightButtonColor,
              onPressed: (widget.readOnly) ? null : () => {_onTap(field)},
              child: Text("+",textAlign: TextAlign.center)))
            /*
          SizedBox(
            width: 25,
            child: IconButton(
            icon: Icon(Icons.arrow_right),
            //color: Colors.yellow,
            onPressed: (widget.readOnly) ? null : () => {_onTap(field)}
            )
          )*/
        ]);
      }
      listOfWidget.add(optionBox);
    });

    return Column (children: listOfWidget);    
  }
}
