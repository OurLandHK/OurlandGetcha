import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';

class PhoneAuthenticationScreen extends StatefulWidget {
  @override
  _PhoneAuthenticationScreenState createState() => new _PhoneAuthenticationScreenState();
}

class _PhoneAuthenticationScreenState extends State<PhoneAuthenticationScreen> {
  UserService userService = new UserService();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String username;
  String address;
  String phoneNumber;
  String avatarUrl = 'assets/images/default-avatar.jpg';
  String smsCode;
  String verificationId;


  void verify(context) {
    if(this.username == null) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(VAL_USERNAME_NULL_TEXT)));
    } else if(this.phoneNumber == null) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(VAL_PHONE_NUMBER_NULL_TEXT)));
    } else if(this.phoneNumber.startsWith('+') == false){
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(VAL_PHONE_NUMBER_INCORRECT_FORMAT_TEXT)));
    } else{
      verifyPhone(context);
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
        timeout: const Duration(seconds: 5),
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
                      userService.createUser(user.uid, this.username, this.avatarUrl, this.address).then((user) {
                        if(user == null) {
                          _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(REG_FAILED_TO_CREATE_USER_TEXT)));
                        } else {
                          Navigator.of(context).pop();
                          //Navigator.of(context).pushReplacementNamed('/home');
                          signIn(context);
                        }
                      });
                    } else {
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
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(REG_FAILED_TO_LOGIN_TEXT)));
          }
    }).catchError((e) {
      print(e);
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(REG_FAILED_TO_LOGIN_TEXT)));
    });
  }

  renderAvatar() {
    return Container(
      width: 80.0,
      height: 80.0,
      decoration: new BoxDecoration(
          shape: BoxShape.circle,
          image: new DecorationImage(
              fit: BoxFit.fill,
              image: new ExactAssetImage(DEFAULT_AVATAR_IMAGE_PATH)
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
        keyboardType: TextInputType.number
    );
  }

  renderPhoneNumberField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_PHONE_NUMBER_HINT_TEXT),
        onChanged: (value) {
          this.phoneNumber = value;
        },
        keyboardType: TextInputType.number
    );
  }

  renderAddressField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_ADDRESS_HINT_TEXT),
        onChanged: (value) {
          this.address = value;
        },
        keyboardType: TextInputType.number
    );
  }

  renderSubmitButton(context) {
    return RaisedButton(
        onPressed: () => verify(context),
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
                renderAvatar(),
                renderSizeBox(),
                renderUsernameField(),
                renderSizeBox(),
                renderPhoneNumberField(),
                renderSizeBox(),
                renderAddressField(),
                renderSizeBox(),
                renderSubmitButton(context)
              ],
            )),
      ),
    );
  }
}