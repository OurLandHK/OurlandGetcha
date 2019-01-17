import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneAuthenticationScreen extends StatefulWidget {
  @override
  _PhoneAuthenticationScreenState createState() => new _PhoneAuthenticationScreenState();
}

class _PhoneAuthenticationScreenState extends State<PhoneAuthenticationScreen> {
  UserService userService = new UserService();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String phoneNumber;
  String smsCode;
  String verificationId;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  checkAuth() async {
    prefs = await SharedPreferences.getInstance();
    if(prefs.getString(PREF_USER_UUID) != null) {
       //Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> verifyPhone(context) async {
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      this.verificationId = verId;
    };

    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      this.verificationId = verId;
      smsCodeDialog(context).then((value) {
        print('Signed in');
      });
    };

    final PhoneVerificationCompleted verifiedSuccess = (FirebaseUser user) {
      print('verified');
    };

    final PhoneVerificationFailed veriFailed = (AuthException exception) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(exception.message)));
    };

    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: this.phoneNumber,
        codeAutoRetrievalTimeout: autoRetrieve,
        codeSent: smsCodeSent,
        timeout: const Duration(seconds: 60),
        verificationCompleted: verifiedSuccess,
        verificationFailed: veriFailed);
  }

  Future<bool> smsCodeDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text(SMS_CODE_DIALOG_TITLE),
            content: TextField(
              onChanged: (value) {
                this.smsCode = value;
              },
            ),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              new FlatButton(
                child: Text(SMS_CODE_DIALOG_BUTTON_TEXT),
                onPressed: () {
                  FirebaseAuth.instance.currentUser().then((user) {
                    if (user != null) {
                        userService.userExist(user.uid).then((userExist) {
                          if(userExist) {
                            prefs.setString(PREF_USER_UUID, user.uid);
                            Navigator.of(context).pop();
                            Navigator.of(context).pushReplacementNamed('/home');
                          } else {
                            Navigator.of(context).push(
                              new MaterialPageRoute(
                              builder: (context) => new RegistrationScreen(user)
                              )
                            );
                          }
                        });
                    }
                    else {
                      Navigator.of(context).pop();
                      signIn(context);
                    }
                  });
                },
              )
            ],
          );
        });
  }

  signIn(context) {
    FirebaseAuth.instance
        .signInWithPhoneNumber(verificationId: verificationId, smsCode: smsCode)
        .then((user) {
          if(user != null) {
              userService.userExist(user.uid).then((userExist) {
                if(userExist) {
                  prefs.setString(PREF_USER_UUID, user.uid);
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/home');
                } else {
                  Navigator.of(context).push(
                    new MaterialPageRoute(
                    builder: (context) => new RegistrationScreen(user)
                   )
                  );
                }
              });
          } else {
            _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(REG_FAILED_TO_LOGIN_TEXT)));
          }
    }).catchError((e) {
      print(e);
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(REG_FAILED_TO_LOGIN_TEXT)));
    });
  }

  renderAppLogo() {
    return Container(
      width: 120.0,
      height: 120.0,
      margin: const EdgeInsets.only(bottom: 40.0),
      decoration: new BoxDecoration(
      image: new DecorationImage(
      fit: BoxFit.fill,
        image: new ExactAssetImage(APP_LOGO_IMAGE_PATH),
      )
     )
    );
  }


  renderPhoneNumberField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_PHONE_NUMBER_HINT_TEXT),
        onChanged: (value) {
          this.phoneNumber = value;
        },
        keyboardType: TextInputType.phone
    );
  }

  renderSubmitButton(context) {
    return RaisedButton(
        onPressed: () => verifyPhone(context),
        child: Text(REG_BUTTON_TEXT),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue
    );
  }

  renderSizeBox() {
    return SizedBox(height: 10.0);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      body: new Center(
        child: Container(
            padding: EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                renderAppLogo(),
                renderPhoneNumberField(),
                renderSizeBox(),
                renderSubmitButton(context)
              ],
            )),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  final FirebaseUser user;

  RegistrationScreen(this.user) {
    if (user  == null) {
      throw new ArgumentError("[RegistrationScreen] firebase user cannot be null.");
    }
  }

  @override
  _RegistrationScreenState createState() => new _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {

  UserService userService = new UserService();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String username;
  String address;
  String phoneNumber;
  String smsCode;
  String verificationId;
  File avatarImage;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      avatarImage = image;
    });
  }

  renderSizeBox() {
    return SizedBox(height: 10.0);
  }

  renderAvatar() {
    return GestureDetector(
        onTap: getImage,
        child: Container(
            width: 80.0,
            height: 80.0,
            decoration: new BoxDecoration(
                shape: BoxShape.circle,
                image: new DecorationImage(
                    fit: BoxFit.fill,
                    image: avatarImage == null ? new ExactAssetImage(DEFAULT_AVATAR_IMAGE_PATH) : new ExactAssetImage(avatarImage.path),
                    )
            )
        )
    );
  }

  renderUsernameField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_USERNAME_HINT_TEXT),
        onChanged: (value) {
          this.username = value;
        },
        keyboardType: TextInputType.text
    );
  }

  renderAddressField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_ADDRESS_HINT_TEXT),
        onChanged: (value) {
          this.address = value;
        },
        keyboardType: TextInputType.text
    );
  }

  renderSubmitButton(context) {
    return RaisedButton(
        onPressed: () => validateInput(context),
        child: Text(REG_BUTTON_TEXT),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue
    );
  }

  validateInput(context) {
      if(this.username == null) {
        _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(VAL_USERNAME_NULL_TEXT)));
      } else if(this.phoneNumber == null) {
        _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(VAL_PHONE_NUMBER_NULL_TEXT)));
      } else if(this.phoneNumber.startsWith('+') == false){
        _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(VAL_PHONE_NUMBER_INCORRECT_FORMAT_TEXT)));
      } else{
        register(context);
      }
  }

  register(context) {
    userService.register(widget.user.uid, this.username, this.avatarImage, this.address).then((user) {
      if(user == null) {
        _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(REG_FAILED_TO_CREATE_USER_TEXT)));
      } else {
        prefs.setString(PREF_USER_UUID, user.uuid);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        body: new Center(
            child: Container(
                padding: EdgeInsets.all(25.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      renderAvatar(),
                      renderSizeBox(),
                      renderUsernameField(),
                      renderSizeBox(),
                      renderAddressField(),
                      renderSubmitButton(context)
                    ]
                )),
            ),
        );
  }
}