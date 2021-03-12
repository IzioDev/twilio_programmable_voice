import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meta/meta.dart';
import 'package:twilio_programmable_voice/src/utils/token_utils.dart';

import 'box_utils.dart';
import 'box_service.dart';
import 'events.dart';
import 'token_service.dart';
import 'exceptions.dart';
import 'workmanager_wrapper.dart';
import 'injector.dart';

class TwilioProgrammableVoice {
  CallEvent _currentCallEvent;
  String _accessTokenUrl;

  final MethodChannel _methodChannel =
      const MethodChannel('twilio_programmable_voice');
  final EventChannel _callStatusEventChannel =
      const EventChannel("twilio_programmable_voice/call_status");

  static final TwilioProgrammableVoice _singleton =
      new TwilioProgrammableVoice._internal();

  factory TwilioProgrammableVoice() {
    return _singleton;
  }

  TwilioProgrammableVoice._internal() {
    // Initialization logic goes here.
  }

  /// Must be the first function you call in the TwilioProgrammableVoice package
  ///
  /// This function will store the accessTokenUrl inside the class,
  /// init the background registration strategy and call registerVoice method
  ///
  /// [accessTokenUrl] is the url that return the access token
  ///
  ///
  /// [tokenManagerStrategies] an optional map where you can set defined the strategies you want to use to retrieve tokens
  ///
  /// [headers] optional headers, use by the GET access token strategy
  Future<bool> setUp(
      {@required String accessTokenUrl,
      Map<String, Object> tokenManagerStrategies,
      Map<String, dynamic> headers}) async {
    _setAccessTokenUrl(accessTokenUrl);

    getService<TokenService>()
        .init(strategies: tokenManagerStrategies, headers: headers);
    final bool isRegistrationValid =
        await registerVoice(accessTokenUrl: accessTokenUrl);
    return isRegistrationValid;
  }

  /// Delegate the registration to Twilio and start listening to call status.
  /// You must call setUp method before because it will initialise the
  /// background registration strategy and store the accessTokenUrl
  ///
  /// Throws an error if fail, the error returned by the Twilio Voice.register.
  ///
  /// Returns a bool value representing the registration status
  ///
  /// [accessTokenUrl] an url which returns a valid accessToken when access
  /// by HTTP GET method
  Future<bool> registerVoice({@required String accessTokenUrl}) async {
    bool isRegistrationValid = true;

    String accessToken = await getService<TokenService>()
        .getAccessToken(accessTokenUrl: accessTokenUrl);
    String fcmToken = Platform.isAndroid
        ? await getService<TokenService>().getFcmToken()
        : null;

    try {
      await _methodChannel.invokeMethod(
          'registerVoice', {"accessToken": accessToken, "fcmToken": fcmToken});
      getService<TokenService>().persistAccessToken(accessToken: accessToken);
      // TODO change implementation (see the method comments)
      WorkmanagerWrapper.launchJobInBg(
          accessTokenUrl: accessTokenUrl, accessToken: accessToken);
    } catch (err) {
      print("registration failed");
      isRegistrationValid = false;
      await getService<BoxService>()
          .getBox()
          .then((box) => box.delete(BoxKeys.ACCESS_TOKEN));
      // TODO: doesn't this could make an infinity loop ? yes
      // registerVoice(accessTokenUrl: accessTokenUrl);
    }
    return isRegistrationValid;
  }

  /// Make a call
  ///
  /// [from] this device identity (or number)
  /// [to] the target identity (or number)
  Future<bool> makeCall({@required String from, @required String to}) async {
    final tokenService = getService<TokenService>();

    String accessToken =
        await tokenService.getAccessToken(accessTokenUrl: _accessTokenUrl);

    final durationBeforeAccessTokenExpires =
        getDurationBeforeTokenExpires(accessToken);

    // 15 secondes left to use the token, so we create a fresh one.
    if (durationBeforeAccessTokenExpires.compareTo(Duration(seconds: 15)) < 0) {
      accessToken = await tokenService.accessTokenStrategyBinder(
          accessTokenUrl: _accessTokenUrl);
    }

    return _methodChannel.invokeMethod(
        'makeCall', {"from": from, "to": to, "accessToken": accessToken});
  }

  /// Stop the current call
  Future<void> hangout() {
    return _methodChannel.invokeMethod('stopCall');
  }

  /// Mute the current active call
  Future<void> mute({@required bool setOn}) {
    return _methodChannel.invokeMethod('muteCall', {"setOn": setOn});
  }

  /// Hold the current active call
  Future<void> hold({@required bool setOn}) {
    return _methodChannel.invokeMethod('holdCall', {"setOn": setOn});
  }

  /// Hold the current active call
  Future<void> toggleSpeaker({@required bool setOn}) {
    return _methodChannel.invokeMethod('toggleSpeaker', {"setOn": setOn});
  }

  /// Answer the current call invite
  ///
  /// [iOS] This is just a stub on iOS
  Future<String> answer() {
    return _methodChannel.invokeMethod('answer');
  }

  /// Handle Fcm Message and delegate to Twilio
  Future<bool> handleMessage({@required Map<String, String> data}) {
    return _methodChannel.invokeMethod('handleMessage', {"messageData": data});
  }

  /// Reject the current call invite
  Future<void> reject() {
    return _methodChannel.invokeMethod('reject');
  }

  /// Request microphone permission on the platform
  ///
  /// Return the microphone [PermissionStatus] after trying to request permissions.
  Future<PermissionStatus> requestMicrophonePermissions() async {
    final microphonePermissionStatus = await Permission.microphone.status;

    if (!microphonePermissionStatus.isGranted) {
      return await Permission.microphone.request();
    }

    return microphonePermissionStatus;
  }

  Future<String> getFcmToken() async {
    if (Platform.isAndroid) {
      return _methodChannel.invokeMethod('getFcmToken');
    }
    return "";
  }

  /// Get the incoming calls stream
  Stream<CallEvent> get callStatusStream {
    CallEvent currentCallEvent;

    return _callStatusEventChannel
        .receiveBroadcastStream()
        .where((data) => _containsCall(data['type']))
        .map((data) {
      switch (data['type']) {
        case 'CallInvite':
          currentCallEvent = CallInvite.from(data);
          break;

        case 'CancelledCallInvite':
          currentCallEvent = CancelledCallInvite.from(data);
          break;

        case 'CallConnectFailure':
          currentCallEvent = CallConnectFailure.from(data);
          break;

        case 'CallRinging':
          currentCallEvent = CallRinging.from(data);
          break;

        case 'CallConnected':
          currentCallEvent = CallConnected.from(data);
          break;

        case 'CallReconnecting':
          currentCallEvent = CallReconnected.from(data);
          break;

        case 'CallReconnected':
          currentCallEvent = CallReconnected.from(data);
          break;

        case 'CallDisconnected':
          currentCallEvent = CallDisconnected.from(data);
          break;

        case 'CallQualityWarningChanged':
          currentCallEvent = CallQualityWarningChanged.from(data);
          break;

        default:
          print("default called in stream");
          print(data.toString());
          break;
      }

      _currentCallEvent = currentCallEvent;
      return currentCallEvent;
    });
  }

  void _setAccessTokenUrl([String accessTokenUrl]) {
    if (accessTokenUrl == null) {
      throw AccessTokenUrlIsNullException();
    }

    _accessTokenUrl = accessTokenUrl;
  }

  bool _containsCall(dynamic value) {
    if (value is String) {
      return value.contains("Call");
    }
    return false;
  }

  get getCall => _currentCallEvent;

  dynamic testIos() async {
    return await _methodChannel.invokeMethod('getBatteryLevel');
  }
}
