import 'dart:async';
import 'dart:io' show Platform;

// import 'package:callkeep/callkeep.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:twilio_programmable_voice/twilio_programmable_voice.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twilio_programmable_voice_example/bloc/call_bloc.dart';

// not for iOS
// import 'background_message_handler.dart';
// import 'callkeep_functions.dart';

import 'package:twilio_programmable_voice_example/config/application.dart';
import 'package:twilio_programmable_voice_example/config/routes.dart';

final logger = Logger();

void main() async {
  Logger.level = Level.debug;

  await DotEnv().load('.env');

  runApp(AppComponent());
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  // final FlutterCallkeep _callKeep = FlutterCallkeep();

  Future<void> setUpTwilioProgrammableVoice() async {
    await TwilioProgrammableVoice()
        .requestMicrophonePermissions()
        .then(logger.d);
    // await checkDefaultPhoneAccount();
    // TODO uncomment this when callkeep merge our pull request
    // await checkDefaultPhoneAccount().then((userAccept) {
    //   // we can use this callback to handle the case where the end user refuse to give the telecom manager permission
    //   logger.d("User has taped ok the telecom manager permission dialog : " + userAccept.toString());
    // });

    await DotEnv().load('.env');
    final accessTokenUrl = DotEnv().env['ACCESS_TOKEN_URL'];

    final platform = Platform.isAndroid ? "/android" : "/ios";

    TwilioProgrammableVoice().setUp(
        accessTokenUrl: accessTokenUrl + platform,
        headers: {
          "TestHeader": "I'm a test header"
        }).then((isRegistrationValid) {
      logger.d("registration is valid: " + isRegistrationValid.toString());
    });
  }

  // Future<bool> checkDefaultPhoneAccount() async {
  //   logger.d('[checkDefaultPhoneAccount]');
  //   final bool hasPhoneAccount = await _callKeep.hasPhoneAccount();
  //
  //   if (!hasPhoneAccount) {
  //     logger.d("Doesn't have phone account, asking for permission");
  //     // TODO return this when callkeep merge our pull request
  //     await _callKeep.hasDefaultPhoneAccount(context, <String, dynamic>{
  //       'alertTitle': 'Permissions required',
  //       'alertDescription':
  //       'This application needs to access your phone accounts',
  //       'cancelButton': 'Cancel',
  //       'okButton': 'ok',
  //     });
  //   }
  //
  //   return hasPhoneAccount;
  // }

  Future<void> displayMakeCallScreen(
      String targetNumber, String callerDisplayName) async {
    logger.d('[displayMakeCallScreen] called');

    final String callUUID = TwilioProgrammableVoice().getCall.sid;
    // await checkDefaultPhoneAccount();

    logger.d(
        '[displayMakeCallScreen] uuid: $callUUID, targetNumber: $targetNumber, displayName: $callerDisplayName');

    // Display a start call screen
    // _callKeep.startCall(callUUID, targetNumber, callerDisplayName);
  }

  Future<void> displayIncomingCallInvite(
      String callerNumber, String callerDisplayName) async {
    logger.d('[displayIncomingCallInvite] called');

    // TODO: review how getCall works to separate calls and call invites
    final String callUUID = TwilioProgrammableVoice().getCall.sid;
    // await checkDefaultPhoneAccount();

    logger.d(
        '[displayIncomingCallInvite] uuid: $callUUID, callerNumber: $callerNumber, displayName: $callerDisplayName');

    // _callKeep.displayIncomingCall(callUUID, callerNumber,
    //     handleType: 'number',
    //     hasVideo: false,
    //     localizedCallerName: callerDisplayName);
  }

  @override
  void initState() {
    super.initState();
    // initCallKeep(_callKeep);

    // _firebaseMessaging.configure(
    //   onMessage: (Map<String, dynamic> message) async {
    //     logger.d('[onFirebaseMessage]', message);
    //     // It's a real push notification
    //     if (message["notification"]["title"] != null) {}

    //     // It's a data
    //     if (message.containsKey("data") && message["data"] != null) {
    //       // It's a twilio data message
    //       logger.d("Message contains data", message["data"]);
    //       if (message["data"].containsKey("twi_message_type")) {
    //         logger.d("Message is a Twilio Message");

    //         final dataMap = Map<String, String>.from(message["data"]);

    //         TwilioProgrammableVoice().handleMessage(data: dataMap);
    //         logger.d(
    //             "TwilioProgrammableVoice().handleMessage called in main.dart");
    //       }
    //     }
    //   },
    //   // onBackgroundMessage: myBackgroundMessageHandler,
    //   onBackgroundMessage: null,
    //   onLaunch: (Map<String, dynamic> message) async {
    //     logger.d("onLaunch: $message");
    //   },
    //   onResume: (Map<String, dynamic> message) async {
    //     logger.d("onResume: $message");
    //   },
    // );

    setUpTwilioProgrammableVoice();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Twilio Programming Voice'),
          ),
          body: Column(
            children: [
              FlatButton(
                  onPressed: () async {
                    print("MAKE CALL");
                    final hasSucceed = await TwilioProgrammableVoice()
                        .makeCall(from: "testId", to: "+33651727985");
                    print("AFTER MAKE CALL");

                    print("Make call success state $hasSucceed");

                    // Notify BLoC we've emitted a call
                    // Note: we could have moved .makeCall call to BLoC
                    context
                        .read<CallBloc>()
                        .add(CallEmited(contactPerson: "+33651727985"));

                    Application.router.navigateTo(context, Routes.call);
                  },
                  child: Text('Make call')),
            ],
          )),
    );
  }
}

class AppComponent extends StatefulWidget {
  @override
  State createState() {
    return AppComponentState();
  }
}

class AppComponentState extends State<AppComponent> {
  AppComponentState() {
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Application.router = router;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        // BLoC is only here to have a call state.
        create: (BuildContext context) => CallBloc(),
        child: MaterialApp(
          title: 'Twilio Programming Voice',
          debugShowCheckedModeBanner: false,
          onGenerateRoute: Application.router.generator,
          initialRoute: Routes.root,
        ));
  }
}
