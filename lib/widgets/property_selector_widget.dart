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
    if(this._value == null) {
      this._value = 0;
    }
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
      this.readOnly,
      this.allowCustom);


  final List<String> defaultFields;
  final List<Property> currentProperties;
  final Function currentSelectProperties;
  final int totalSelect;
  bool showLastUpdate = false;
  bool readOnly = true;
  bool updownProperty = false;
  bool allowCustom = false;

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
  String customField = "";
  Map<String, Property> _currentPropertiesMap;
  PropertySelectorModel() {
  }

  @override
  void initState() {
    _currentPropertiesMap = new Map();
    //print("Current Properties ${widget.currentProperties.length}");
    for(int i = 0; i< widget.currentProperties.length; i++) {
      String field = widget.currentProperties[i].propertyField;
      //print("field ${field} ${widget.currentProperties[i].value}");
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
    if(widget.currentSelectProperties !=  null) {
      widget.currentSelectProperties(selectedFields, true);
    }
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
    if(widget.currentSelectProperties !=  null) {
      widget.currentSelectProperties(selectedDownFields, false);
    }
  }
  Widget buildOption(BuildContext context, String field, Property property, bool displayResult) {
      double borderSize = 1.2;
      double optionWidth = MediaQuery.of(context).size.width;
      Color boxColor = Theme.of(context).dialogBackgroundColor;
      Color leftButtonColor = Theme.of(context).dialogBackgroundColor;
      Color rightButtonColor = Theme.of(context).dialogBackgroundColor;
      String resultText = "";
      String fieldText = field;
      double optionBoxWidth = optionWidth;
      if(widget.updownProperty) {
        if(!widget.readOnly) {
          optionBoxWidth -= 120;
        }
      }
      Widget textWidget;
      if(property != null) {
        textWidget = Text(fieldText);
      } else {
        textWidget = SizedBox(
            width: optionBoxWidth - 40,
            child: TextField(   
          //  textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              hintText: HINT_CUSTOM_PROPERTY,
            ),
            textAlign: TextAlign.center,
            onChanged: (String value) {
              setState(() {this.customField = value;});},
        // validator: _validateName,
          )
        );
      }
      int value = 0;
      int downValue = 0;
      if(property != null) {
        value = property.value;
        downValue = property.downValue;        
      }

      LinearGradient gradient;
      if(selectedFields.contains(field)) {
        value++;
        borderSize = 2;
        boxColor = Theme.of(context).accentColor;
        rightButtonColor = Colors.yellow;
      }
      if(widget.updownProperty) {
        if(downValue == null) {
          downValue = 0;
        }
        //print("${field} ${downValue}");
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
        if(widget.showLastUpdate && property != null && property._lastUpdate != null) {
          String lastUpdateText = LABEL_LAST_UPDATE + DateFormat('dd MMM kk:mm').format(
          new DateTime.fromMicrosecondsSinceEpoch(
            property._lastUpdate.microsecondsSinceEpoch));
          resultText += lastUpdateText;
          textWidget = Column(children: [
            textWidget,
            Text(lastUpdateText ,style: Theme.of(context).textTheme.subtitle),
          ]);
        }
        String valueText = "";
        String valueDownText = "";
        if(displayResult && property != null) {
          valueText = " " + value.toString();
          valueDownText = " " + downValue.toString() + " ";
        }        
        if(property != null) {
          textWidget = Row(children: [
            Text(valueText),
            Flexible(flex: 2,child: Container()),
            textWidget,
            Flexible(flex: 2,child: Container()),
            Text(valueDownText),
          ]);           
        }
      } else {
        if(widget.showLastUpdate && property != null && property._lastUpdate != null) {
          String lastUpdateText = LABEL_LAST_UPDATE + DateFormat('dd MMM kk:mm').format(
          new DateTime.fromMicrosecondsSinceEpoch(
            property._lastUpdate.microsecondsSinceEpoch));
          resultText += lastUpdateText;
        }
        if(displayResult) {
          resultText += "   " + value.toString();
        }
        if(property != null) {
          textWidget = Row(children: [
            textWidget,
            Flexible(flex: 2,child: Container()),
            Text(resultText),
          ]);
        }
      }
      Widget optionBox = SizedBox(
          width: optionBoxWidth,
          child: Container(
            decoration: new BoxDecoration(
              gradient: gradient,
              color: boxColor,
            ),
            child: widget.readOnly || property == null ? textWidget :
            FlatButton(
              child: textWidget, 
              onPressed:  () => {_onTap(field)}
            )
          )
        );
      if(widget.updownProperty && !widget.readOnly) {
        optionBox = Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          SizedBox(
            width: 40,
            child: RaisedButton(
              color: leftButtonColor,
              onPressed: (widget.readOnly) ? null : () => {_onTapDown(field)},
              child: Text("-",textAlign: TextAlign.center,))),
          Container(),
          optionBox,
          Container(),
          SizedBox(
            width: 40,
            child: RaisedButton(
              color: rightButtonColor,
              onPressed: (widget.readOnly) ? null : () => {_onTap(field)},
              child: Text("+",textAlign: TextAlign.center)))
        ]);
      }
      return optionBox;
  }

  Widget buildOptions(BuildContext context, bool displayResult) {
    List<Widget> listOfWidget = [];
    _currentPropertiesMap.forEach((field, property) {
      Widget optionBox = buildOption(context, field, property, displayResult);
      listOfWidget.add(optionBox);
    });
    if(widget.allowCustom) {
      listOfWidget.add(buildOption(context, customField, null, displayResult));
    }

    return Column (children: listOfWidget);    
  }
}
