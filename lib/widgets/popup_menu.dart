import 'package:flutter/material.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/pages/about.dart';
import 'package:ourland_native/pages/settings.dart';
import 'package:ourland_native/pages/registration_screen.dart';


final List<String> items = <String>[
  MENU_ITEM_SETTINGS,
  MENU_ITEM_ABOUT,
  MENU_ITEM_LOGOUT
];

class PopupMenu extends StatelessWidget {
  UserService userService = new UserService();

  void _select(BuildContext context, String item) {
    if(item == MENU_ITEM_SETTINGS) {
      Navigator.of(context).push(
          new MaterialPageRoute(
              builder: (context) => SettingsScreen()
          )
      );
    } else if(item == MENU_ITEM_ABOUT) {
      Navigator.of(context).push(
          new MaterialPageRoute(
              builder: (context) => About()
          )
      );
    } else if(item == MENU_ITEM_LOGOUT){
      userService.logout();

      Navigator.of(context).pushReplacement(
          new MaterialPageRoute(
              builder: (context) => PhoneAuthenticationScreen()
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
        elevation: 3.2,
        initialValue: items[0],
        onSelected: (String item) {
          _select(context, item);
        },
        itemBuilder: (BuildContext context) {
          return items.map((String item) {
            return PopupMenuItem<String>(
                value: item,
                child: Text(item),
                );
          }).toList();
        }
    );
  }
}