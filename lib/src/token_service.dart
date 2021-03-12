import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meta/meta.dart';
import 'package:twilio_programmable_voice/src/box_service.dart';
// import 'package:flutter_apns/flutter_apns.dart';
// import 'package:twilio_programmable_voice/src/callback_dispatcher.dart';
import 'package:twilio_programmable_voice/twilio_programmable_voice.dart';

import 'box_utils.dart';
import 'exceptions.dart';
import 'injector.dart';

class TokenService {
  static const _DEFAULT_CONFIG = {
    BoxKeys.ACCESS_TOKEN_STRATEGY: AccessTokenStrategy.GET,
    BoxKeys.FCM_TOKEN_STRATEGY: FcmTokenStrategy.FIREBASE_MESSAGING
  };

  Dio client;

  TokenService({Dio mock}) {
    this.client = mock ?? Dio();
  }

  Future<void> init(
      {Map<String, String> strategies, Map<String, dynamic> headers}) async {
    bool strategiesDefined = await areStrategiesDefined();
    if (strategies != null) {
      return setUpStrategies(strategies: strategies);
    } else if (!strategiesDefined) {
      return setUpStrategies(strategies: _DEFAULT_CONFIG);
    }

    if (headers != null) {
      await setHeaders(headers: headers);
    }
  }

  @visibleForTesting
  Future<void> setUpStrategies(
      {@required Map<String, Object> strategies}) async {
    if (!strategies.containsKey(BoxKeys.ACCESS_TOKEN_STRATEGY) &&
        !strategies.containsKey(BoxKeys.FCM_TOKEN_STRATEGY)) {
      throw SettingNonExistingStrategiesException();
    }

    await getService<BoxService>().getBox().then((box) {
      if (strategies[BoxKeys.ACCESS_TOKEN_STRATEGY] != null) {
        box.put(BoxKeys.ACCESS_TOKEN_STRATEGY,
            strategies[BoxKeys.ACCESS_TOKEN_STRATEGY]);
      } else if (strategies.containsKey(BoxKeys.ACCESS_TOKEN_STRATEGY)) {
        throw NoValuePassToAccessTokenStrategyException();
      }

      if (strategies[BoxKeys.FCM_TOKEN_STRATEGY] != null) {
        box.put(
            BoxKeys.FCM_TOKEN_STRATEGY, strategies[BoxKeys.FCM_TOKEN_STRATEGY]);
      } else if (strategies.containsKey(BoxKeys.FCM_TOKEN_STRATEGY)) {
        throw NoValuePassFcmTokenStrategyException();
      }
    });
  }

  @visibleForTesting
  Future<bool> areStrategiesDefined() async {
    return await getService<BoxService>().getBox().then((box) {
      return (box.get(BoxKeys.ACCESS_TOKEN_STRATEGY) != null &&
          box.get(BoxKeys.FCM_TOKEN_STRATEGY) != null);
    });
  }

  Future<String> getAccessToken({@required String accessTokenUrl}) async {
    String accessToken = await getService<BoxService>()
        .getBox()
        .then((box) => box.get(BoxKeys.ACCESS_TOKEN));
    if (accessToken == null) {
      accessToken =
          await accessTokenStrategyBinder(accessTokenUrl: accessTokenUrl);
    }

    return accessToken;
  }

  Future<String> accessTokenStrategyBinder(
      {@required String accessTokenUrl}) async {
    return await getService<BoxService>().getBox().then((box) async {
      if (box.get(BoxKeys.ACCESS_TOKEN_STRATEGY) == AccessTokenStrategy.GET) {
        return await _httpGetAccessTokenStrategy(
            accessTokenUrl: accessTokenUrl);
      } else {
        throw UndefinedAccessTokenStrategyException();
      }
    });
  }

  Future<String> _httpGetAccessTokenStrategy(
      {@required String accessTokenUrl}) async {
    final headers = await getHeaders();
    final tokenResponse =
        await client.get(accessTokenUrl, options: Options(headers: headers));
    return tokenResponse.data;
  }

  Future<void> persistAccessToken({@required String accessToken}) async {
    await getService<BoxService>()
        .getBox()
        .then((box) => box.put(BoxKeys.ACCESS_TOKEN, accessToken));
  }

  Future<void> removeAccessToken() async {
    await getService<BoxService>().getBox().then((box) {
      box.delete(BoxKeys.ACCESS_TOKEN);
    });
  }

  @visibleForTesting
  Future<void> setHeaders({@required Map<String, dynamic> headers}) async {
    await getService<BoxService>()
        .getBox()
        .then((box) => box.put(BoxKeys.HEADERS, headers));
  }

  @visibleForTesting
  Future<Map<String, dynamic>> getHeaders() async {
    final headers = await getService<BoxService>()
        .getBox()
        .then((box) => box.get(BoxKeys.HEADERS));

    return (headers != null) ? Map<String, dynamic>.from(headers) : null;
  }

  Future<String> getFcmToken() async {
    print("[TokenService] getFcmToken called");
    return await _fcmTokenStrategyBinder();
  }

  Future<String> _fcmTokenStrategyBinder() async {
    print("[TokenService] _fcmTokenStrategyBinder called");
    return await getService<BoxService>().getBox().then((box) {
      if (box.get(BoxKeys.FCM_TOKEN_STRATEGY) ==
          FcmTokenStrategy.FIREBASE_MESSAGING) {
        return _firebaseMessagingFcmTokenStrategy();
      } else {
        throw UndefinedFcmTokenStrategyException();
      }
    });
  }

  Future<String> _firebaseMessagingFcmTokenStrategy() {
    return TwilioProgrammableVoice().getFcmToken();
  }
}
