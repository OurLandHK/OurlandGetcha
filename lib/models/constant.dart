import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

const GeoPoint HongKongGeoPoint = GeoPoint(22.319118313228618,114.16929289698601);

const String APP_NAME = "我地.壁報";
const String ABOUT_TEXT = "一塊會主動通知用戶的地區連儂牆街坊可以查詢任何位置附近 1-3 公里內發生的社區事件，篩選自已有興趣的訊息，如公共設施，活動，社區議題落手參與。街坊可以隨時隨地「報料」: 匯報社區問題，仲可以一直跟進事態發展。\n在危急時通知附近用戶求救！";
const String SMS_CODE_DIALOG_TITLE = "入 SMS Code";
const String SMS_CODE_DIALOG_BUTTON_TEXT = "核實";
const String REG_BUTTON_TEXT = "註冊";
const String GOOGLE_REG_BUTTON_TEXT = "用Google ID 註冊/登入";
const String PHONE_REG_BUTTON_TEXT = "用電話號碼註冊/登入";
const String NOBODY_BUTTON_TEXT = "做CDROM";
const String REG_USERNAME_HINT_TEXT = "輸入用戶名稱";
const String OURLAND_SEARCH_HOST = "https://ourlandtest.firebaseapp.com";
//const String OURLAND_SEARCH_HOST = "https://ourland.hk";

const String REG_PHONE_NUMBER_HINT_TEXT = "輸入香港電話號碼: ########";
const String REG_FAILED_TO_CREATE_USER_TEXT = "註冊唔到";
const String REG_FAILED_TO_LOGIN_TEXT = "Login唔到";
const String DEFAULT_AVATAR_IMAGE_PATH = "assets/images/default-avatar.jpg";
const String APP_LOGO_IMAGE_PATH = "assets/images/BigPostLogo.png";
const String SEARCHING_APP_LOGO_IMAGE_PATH = "assets/images/app-logo.png";
const String VAL_USERNAME_NULL_TEXT = '請輸入用戶名稱';
const String VAL_PHONE_NUMBER_NULL_TEXT = '請輸入香港電話號碼:';
const String VAL_PHONE_NUMBER_INCORRECT_FORMAT_TEXT = '電話號碼要入 ########';

const String FIRESTORE_USER_AVATAR_IMG_PATH = "images/userAvatarImages/";
const String PREF_USER_UUID = "PREF_USER_PROFILE";
const String JPEG_EXTENSION = ".jpeg";

const String CHAT_NTH_TO_SEND = "冇野Send";
const String CHAT_FILE_NOT_IMG = "呢張唔係相";
const String LABEL_CHOICE_OTHER_TAG = "冇貨, 選過第二樣";

const String MESSAGE_HIDE = "隱藏不恰當訊息";
const String MESSAGE_SHOW = "解除隱藏";
const String MESSAGE_BROADCAST = "推上香港·主牆";
const String MESSAGE_LOCAL = "回到地區";

const String LABEL_NEARBY = "附近";
const String LABEL_REGION = "地點 ";
const String LABEL_REGION0 = LABEL_REGION + "1";
const String LABEL_REGION1 = LABEL_REGION + "2";

const String LABEL_BROADCAST = "香港·主牆";
const String LABEL_RECENT = "睇過";
const String LABEL_BOOKMARK = "跟";

const String MENU_ITEM_SETTINGS = "設定";
const String MENU_ITEM_SETTINGS_CHANGE_HOME_LOCATION = "收風地點1";
const String MENU_ITEM_SETTINGS_CHANGE_OFFICE_LOCATION = "收風地點2";
const String MENU_ITEM_SETTINGS_CHANGE_PROFILE_IMAGE = "設定照片（實名Memo 先出）";
const String MENU_ITEM_NOT_FOUND_ERR = "冇貨";

const String MENU_ITEM_ABOUT = "關於";
const String MENU_ITEM_LOGOUT = "變CD-ROM";
const String CHAT_MENU_ITEM_REPORT = "我要做撕紙🐶";
const String REPORT_APPROVED = "真・撕紙🐶";
const String REPORT_COVERD= "我幫你遮咗佢";
const String REPORT_DESC = "啲Memo係冇咁易撕㗎！不過如果你唔想見到佢，俾個原因我哋就可以幫你遮咗佢。如果有好多人都遮咗，咁Admin會好大機會變成真・撕紙🐶㗎喇！";

const String LABEL_IN = "在";
const String LABEL_HAS = "有";
const String TAG_ALL = "所有";
const List<String> SEARCHING_STATUS_OPTIONS = ['開緊', '完結', '政府跟進中', '流料', '不恰當訊息'];
const List<String> TAG_SELECTION =  ["吹水", "突發","活動", "優惠/美食", "投票", "秘境", "維修/求助", "交換", "我地.市正"];
const String LABEL_TOPIC = "Memo";
const String LABEL_NEW_TOPIC = "新Memo";
const String LABEL_NEW_BROADCAST_TOPIC = "新廣播";
const String LABEL_UPDATE_TOPIC = " 有變";
const String LABEL_SHOW = "開來見我";
const String LABEL_CLOSE = "拜拜";
const String HINT_TOPIC = "入D搶眼 Memo 標題";
const String LABEL_DETAIL = "詳情";
const String HINT_DEATIL = "入D 詳情 如 時，地，人？";
const String HELPER_DETAIL = "可用 Hash Tag";
const String LABEL_MUST_SHOW_NAME = "要其他人實名回答";
const String LABEL_MUST_SHOW_NAME_SIMPLE = "實名";
const String LABEL_MISSING_TOPIC = "冇入標題";
const String LABEL_MORE_DETAIL = "入D詳情先出Memo好D";
const String LABEL_SEND = "出Memo";
const String LABEL_NOBODY = "沒有人";
const String LABEL_DISTRICT ="社區";
const String LABEL_CARE ="關心";
const String PERM_LOCATION_NOT_GRANTED = "唔該俾我用 GPS";
const String PERM_LOCATION_GRANT_BTN_TEXT = "俾";
const String PERM_LOCATION_NOT_GRANT_BTN_TEXT = "唔俾";

const String NEW_HOME_LOCATION = "入新地點1";
const String NEW_OFFICE_LOCATION = "入新地點2";
const String UPDATE_LOCATION_BTN_TEXT = "確認地點";
const String UPDATE_LOCATION_SUCCESS = "地點更新成功";
const String LABEL_RECENT_SEARCHING = "最新正料";

const String HINT_SEARCH_LOCATION = "輸入指定地方找正料";
const String HINT_SEARCH_NEARBY_LOCATION = "找附近或輸入指定地方的正料";

const String NO_PLACE_CALLED = "找不到 -》";

const String TOPIC_ROOT_ID = "";

const String LABEL_TIME = "時間\n";
const String LABEL_START_TIME = "開始: ";
const String LABEL_DATE = "日期: ";
const String LABEL_END_TIME = "完結: ";
const String LABEL_OPENNING_HOUR = "開放時間: ";
const String LABEL_EVERYDAY = "每日: ";
const List<String> LABEL_WEEKLY = ["日: ","一: ","二: ","三: ","四: ","五: ","六: "];

const String LABEL_CLOSED = "關閉";
const String LABEL_DURATION = "為期";
const String LABEL_VOTED = "閣下已投票 ";
const String LABEL_VOTE = "我要投票"; 
const String LABEL_KM = "km";
const String LABEL_VOTE_MAX = "最多可投票數：";
const String LABEL_VOTE_RANGE ="投票範圍：";
const String LABEL_LAST_UPDATE ="最後更新: ";

const double MAP_HEIGHT = 200.0;
const double TOOLBAR_HEIGHT = 25.0;
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
  Color(0xFFA7A7EA),
  Color(0xFFCAF0F8),
  Color(0xFFD0D0D0),
];

const List<String> TagList = [
  "公共設施",
  "活動",
  "義工招募",
  "寵物",
  "兒童遊樂場",
  "社區匯報",
  "環保",
  "社區規劃",
];

const List<String> BlockLevels = [
  "有人想撕 - 自行負責觀看風險",
  "撕下了 - 不能觀看",
];

const List<String> BlockReasons = [
  "裸露",
  "暴力",
  "騷擾",
  "傷害生命",
  "不實消息",
  "內容農場",
  "賣違禁品",
  "仇恨言論",
  "恐怖主義",
  "其他",
];

const List<Color> TOPIC_COLORS_DARKER = [
  Color(0xff714641),
  Color(0xFF765A02),
  Color(0xFF807239),
  Color(0xFF658048),
  Color(0xFF537876),
  Color(0xFF737454),
  Color(0xFF747570),
  Color(0xFF545475),
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