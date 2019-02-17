import 'dart:ui';

const String APP_NAME = "我地.佳招";
const String SMS_CODE_DIALOG_TITLE = "Enter SMS Code";
const String SMS_CODE_DIALOG_BUTTON_TEXT = "Verify";
const String REG_BUTTON_TEXT = "Submit";
const String REG_USERNAME_HINT_TEXT = "Enter Username";

const String REG_PHONE_NUMBER_HINT_TEXT = "Enter Phone number: XXXX XXXX";
const String REG_ADDRESS_HINT_TEXT = "Home / Office Address (Optional)";
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

const String LABEL_NEARBY = "NearBy";
const String LABEL_REGION0 = "Home";
const String LABEL_REGION1 = "Office";

const String MENU_ITEM_SETTINGS = "Settings";
const String MENU_ITEM_ABOUT = "About";
const String MENU_ITEM_LOGOUT = "Logout";

const String LABEL_IN = "在";
const String LABEL_HAS = "有";
const List<String> TAG_SELECTION =  ["吹水", "活動", "優惠", "美食", "秘境", "維修"];
const String LABEL_TOPIC = "Topic";
const String HINT_TOPIC = "Topic Hint";
const String LABEL_DETAIL = "Detail";
const String HINT_DEATIL = "Detail Hint";
const String HELPER_DETAIL = "Hash Tag Support";
const String LABEL_MUST_SHOW_GEO = "Reply need to show location";
const String LABEL_MISSING_TOPIC = "Missing Topic";
const String LABEL_MORE_DETAIL = "More Detail is Better";
const String LABEL_SEND = "Send";
const String LABEL_NOBODY = "沒有人";
const String PERM_LOCATION_NOT_GRANTED = "Location permission is required";
const String PERM_LOCATION_GRANT_BTN_TEXT = "Retry";


const String TOPIC_ROOT_ID = "";

const double MAP_HEIGHT = 200.0;
const double CREATE_TOPIC_MAP_HEIGHT = 150.0;

final themeColor = Color(0xfff5a623);
final primaryColor = Color(0xff203152);
final greyColor = Color(0xffaeaeae);
final greyColor2 = Color(0xffE8E8E8);