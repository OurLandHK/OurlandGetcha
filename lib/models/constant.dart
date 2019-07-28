import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

const String APP_NAME = "我地.壁報";
const String SMS_CODE_DIALOG_TITLE = "入 SMS Code";
const String SMS_CODE_DIALOG_BUTTON_TEXT = "Verify";
const String REG_BUTTON_TEXT = "註冊";
const String NOBODY_BUTTON_TEXT = "做CDROM";
const String REG_USERNAME_HINT_TEXT = "Enter Username";
const String OUTLAND_SEARCH_HOST = "https://ourlandtest.firebaseapp.com";

const String REG_PHONE_NUMBER_HINT_TEXT = "Enter Phone number: XXXX XXXX";
const String REG_FAILED_TO_CREATE_USER_TEXT = "Failed to create a user";
const String REG_FAILED_TO_LOGIN_TEXT = "Failed to login";
const String DEFAULT_AVATAR_IMAGE_PATH = "assets/images/default-avatar.jpg";
const String APP_LOGO_IMAGE_PATH = "assets/images/app-logo.png";
const String VAL_USERNAME_NULL_TEXT = 'Please enter username';
const String VAL_PHONE_NUMBER_NULL_TEXT = 'Please enter phone number';
const String VAL_PHONE_NUMBER_INCORRECT_FORMAT_TEXT = 'The format of the phone number provided is incorrect. Please enter the phone number in a format that can be parsed into E.164 format. E.164 phone numbers are written in the format [+][country code][subscriber number including area code]. [ Invalid format. ]';

const String FIRESTORE_USER_AVATAR_IMG_PATH = "images/userAvatarImages/";
const String PREF_USER_UUID = "PREF_USER_PROFILE";
const String JPEG_EXTENSION = ".jpeg";

const String CHAT_NTH_TO_SEND = "Nothing to send";
const String CHAT_FILE_NOT_IMG = "This file is not an image";
const String LABEL_CHOICE_OTHER_TAG = "冇貨, 選過第二樣";

const String MESSAGE_HIDE = "隱藏不恰當訊息";
const String MESSAGE_SHOW = "解除隱藏";

const String LABEL_NEARBY = "NearBy";
const String LABEL_REGION0 = "Home";
const String LABEL_REGION1 = "Office";

const String LABEL_BROADCAST = "廣播";
const String LABEL_RECENT = "Recent";
const String LABEL_BOOKMARK = "跟";

const String MENU_ITEM_SETTINGS = "Settings";
const String MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION = "Change Home Location";
const String MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION = "Change Office Location";
const String MENU_ITEM_SETTINGS_CHANGE_PROFILE_IMAGE = "Change Profile Image";
const String MENU_ITEM_NOT_FOUND_ERR = "Meun item not found";

const String MENU_ITEM_ABOUT = "About";
const String MENU_ITEM_LOGOUT = "Logout";

const String LABEL_IN = "在";
const String LABEL_HAS = "有";
const String TAG_ALL = "所有";
const List<String> TAG_SELECTION =  ["吹水", "突發","活動", "優惠", "美食", "秘境", "維修", "遊戲", "交換", "我地.市正"];
const String LABEL_TOPIC = "Memo";
const String LABEL_NEW_TOPIC = "新Memo";
const String LABEL_NEW_BROADCAST_TOPIC = "新廣播";
const String LABEL_UPDATE_TOPIC = " has been updated";
const String LABEL_SHOW = "Show";
const String LABEL_CLOSE = "Close";
const String HINT_TOPIC = "Topic Hint";
const String LABEL_DETAIL = "Detail";
const String HINT_DEATIL = "Detail Hint";
const String HELPER_DETAIL = "Hash Tag Support";
const String LABEL_MUST_SHOW_NAME = "實名回答";
const String LABEL_MUST_SHOW_NAME_SIMPLE = "實名";
const String LABEL_MISSING_TOPIC = "Missing Topic";
const String LABEL_MORE_DETAIL = "More Detail is Better";
const String LABEL_SEND = "Send";
const String LABEL_NOBODY = "沒有人";
const String PERM_LOCATION_NOT_GRANTED = "Location permission is required";
const String PERM_LOCATION_GRANT_BTN_TEXT = "Retry";

const String NEW_HOME_LOCATION = "New Home Location";
const String NEW_OFFICE_LOCATION = "New Office Location";
const String UPDATE_LOCATION_BTN_TEXT = "Update Location";
const String UPDATE_LOCATION_SUCCESS = "Updated Location Successfully";

const String TOPIC_ROOT_ID = "";

const double MAP_HEIGHT = 200.0;
const double CREATE_TOPIC_MAP_HEIGHT = 150.0;

final themeColor = Color(0xfff5a623);
final primaryColor = Color(0xff203152);
final greyColor = Color(0xffaeaeae);
final greyColor2 = Color(0xffE8E8E8);

const List<Color> TOPIC_COLORS = [
  Color(0xffF28B83),
  Color(0xFFFCBC05),
  Color(0xFFFFF476),
  Color(0xFFCBFF90),
  Color(0xFFA7FEEA),
  Color(0xFFE6C9A9),
  Color(0xFFE8EAEE),
  Color(0xFFA7FEEA),
  Color(0xFFCAF0F8),
  Color(0xFFFFFFFF),

];

const List<Color> TOPIC_COLORS_DARKER = [
  Color(0xff714641),
  Color(0xFF765A02),
  Color(0xFF807239),
  Color(0xFF658048),
  Color(0xFF537876),
  Color(0xFF737454),
  Color(0xFF747570),
  Color(0xFF547575),
  Color(0xFF657574),
  Color(0xFF808080),
];

List<DropdownMenuItem<String>> getDropDownMenuItems(List<String> labelList, bool wildcard) {
    List<DropdownMenuItem<String>> items = new List();
    if(wildcard) {
      items.add(new DropdownMenuItem(
          value: "",
          child: new Text(TAG_ALL)
      ));      
    }
    for (String label in labelList) {
      items.add(new DropdownMenuItem(
          value: label,
          child: new Text(label)
      ));
    }
    return items;
  }