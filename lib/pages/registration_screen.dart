import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/ourland_home.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

class PhoneAuthenticationScreen extends StatefulWidget {
  SharedPreferences preferences;
  bool firstPage;
  PhoneAuthenticationScreen({Key key, @required this.preferences, isFirstPage}) : super(key: key) {
    firstPage = true;
    if(isFirstPage != null) {
      firstPage = isFirstPage;
    }
  }
  @override
  _PhoneAuthenticationScreenState createState() =>
      new _PhoneAuthenticationScreenState();
}

class _PhoneAuthenticationScreenState extends State<PhoneAuthenticationScreen> {
  UserService userService = new UserService();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String phoneNumber;
  String smsCode;
  String verificationId;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  checkAuth() async {
    FirebaseUser fbuser = await _auth.currentUser();
    if (fbuser != null) {
      UserService userService = new UserService();
      userService.getUser(fbuser.uid).then((user) {
        Navigator.of(context).pushReplacement(
            new MaterialPageRoute(builder: (context) => OurlandHome(user, widget.preferences)));
      });
    }
  }

  verifyPhoneField(context) {
    if (this.phoneNumber == null) {
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: new Text(VAL_PHONE_NUMBER_NULL_TEXT)));
    }
//    else if(this.phoneNumber.startsWith('+') == false){
//      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(VAL_PHONE_NUMBER_INCORRECT_FORMAT_TEXT)));
//    }
    else {
      verifyPhone(context);
    }
  }

  Future<void> verifyPhone(context) async {
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      this.verificationId = verId;
    };

    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: new Text("SMS Sent")));
      this.verificationId = verId;
      smsCodeDialog(context).then((value) {
        print('Signed in');
      });
    };

    final PhoneVerificationCompleted verifiedSuccess = (AuthCredential phoneAuthCredential){
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: new Text("Verified")));
      _auth.signInWithCredential(phoneAuthCredential);
    };

    final PhoneVerificationFailed veriFailed = (AuthException exception) {
      print('falied');
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: new Text(exception.message)));
    };

    await _auth.verifyPhoneNumber(
        // set +852 as default dial code temporarily
        phoneNumber: '+852' + this.phoneNumber,
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
                keyboardType: TextInputType.phone),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              new FlatButton(
                child: Text(SMS_CODE_DIALOG_BUTTON_TEXT),
                onPressed: () {
                  _auth.currentUser().then((fbuser) {
                    if (fbuser != null) {
                      userService.getUser(fbuser.uid).then((user) {
                        if (user != null) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacement(
                              new MaterialPageRoute(
                                  builder: (context) => OurlandHome(user, widget.preferences)));
                        } else {
                          Navigator.of(context).push(new MaterialPageRoute(
                              builder: (context) =>
                                  RegistrationScreen(fbuser, widget.preferences)));
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
    final AuthCredential credential = PhoneAuthProvider.getCredential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    _auth.signInWithCredential(credential)
        .then((FirebaseUser fbuser) {
      print("${fbuser}");
      if (fbuser != null) {
        userService.getUser(fbuser.uid).then((user) {
          if (user != null) {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => OurlandHome(user, widget.preferences)));
          } else {
            Navigator.of(context).push(new MaterialPageRoute(
                builder: (context) => RegistrationScreen(fbuser, widget.preferences)));
          }
        });
      } else {
        _scaffoldKey.currentState.showSnackBar(
            new SnackBar(content: new Text(REG_FAILED_TO_LOGIN_TEXT)));
      }
    }).catchError((e) {
      print(e);
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: new Text(REG_FAILED_TO_LOGIN_TEXT)));
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
        )));
  }

  renderPhoneNumberField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_PHONE_NUMBER_HINT_TEXT),
        onChanged: (value) {
          this.phoneNumber = value;
        },
        keyboardType: TextInputType.phone);
  }

  renderSubmitButton(context) {
    return RaisedButton(
        onPressed: () => verifyPhoneField(context),
        child: Text(REG_BUTTON_TEXT),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue);
  }

  renderAccessAsNobody(content) {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed:  () => Navigator.of(context).pushReplacement(
            new MaterialPageRoute(builder: (context) => OurlandHome(null ,widget.preferences))),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                NOBODY_BUTTON_TEXT,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      )
    );
  }

  renderSizeBox() {
    return SizedBox(height: 10.0);
  }

  Widget _renderGoogleSignInButton() {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed: () {
        _signInWithGoogle();
      /*  .whenComplete(() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return FirstScreen();
              },
            ),
          );
        });
        */
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage("assets/images/google_logo.png"), height: 35.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final FirebaseUser fbuser = await _auth.signInWithCredential(credential);

    assert(!fbuser.isAnonymous);
    assert(await fbuser.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(fbuser.uid == currentUser.uid);
    return userService.getUser(fbuser.uid).then((user) {
          if (user != null) {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => OurlandHome(user, widget.preferences)));
          } else {
            Navigator.of(context).push(new MaterialPageRoute(
                builder: (context) => RegistrationScreen(fbuser, widget.preferences)));
          }
        });

//    return 'signInWithGoogle succeeded: $user';
  }

  void _signOutGoogle() async{
    await _googleSignIn.signOut();

    print("User Sign Out");
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
                renderSizeBox(),
                _renderGoogleSignInButton(),     
                renderSizeBox(),          
                renderPhoneNumberField(),
                renderSizeBox(),
                renderSizeBox(),
                renderSubmitButton(context),    
                renderSizeBox(),       
                (widget.firstPage) ? renderAccessAsNobody(context) : Container(),
              ],
            )),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  final FirebaseUser user;
  final SharedPreferences preferences;

  RegistrationScreen(this.user, this.preferences) {
    if (user == null) {
      throw new ArgumentError(
          "[RegistrationScreen] firebase user cannot be null.");
    }
  }

  @override
  _RegistrationScreenState createState() => new _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  UserService userService = new UserService();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String username;
  String phoneNumber;
  String smsCode;
  String verificationId;
  File avatarImage;

  @override
  void initState() {
    super.initState();
  }

/*
  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      avatarImage = image;
    });
  }
*/
  renderSizeBox() {
    return SizedBox(height: 10.0);
  }

/*
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
                  image: avatarImage == null
                      ? new ExactAssetImage(DEFAULT_AVATAR_IMAGE_PATH)
                      : new ExactAssetImage(avatarImage.path),
                ))));
  }
*/
  renderUsernameField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_USERNAME_HINT_TEXT),
        onChanged: (value) {
          this.username = value;
        },
        keyboardType: TextInputType.text);
  }

  renderSubmitButton(context) {
    return RaisedButton(
        onPressed: () => validateInput(context),
        child: Text(REG_BUTTON_TEXT),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue);
  }

  validateInput(context) {
    if (this.username == null) {
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: new Text(VAL_USERNAME_NULL_TEXT)));
    } else {
      register(context);
    }
  }

  register(context) {
    userService
        .register(
            widget.user.uid, this.username, this.avatarImage)
        .then((user) {
      if (user == null) {
        _scaffoldKey.currentState.showSnackBar(
            new SnackBar(content: new Text(REG_FAILED_TO_CREATE_USER_TEXT)));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => OurlandHome(user, widget.preferences)));
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
          //        renderAvatar(),
                  renderSizeBox(),
                  renderUsernameField(),
                  renderSizeBox(),
                  renderSubmitButton(context)
                ])),
      ),
    );
  }
}
