package fr.izio.twilio_programmable_voice;

import android.util.Log;

import androidx.annotation.NonNull;

import com.google.firebase.messaging.FirebaseMessaging;
import com.twilio.voice.LogLevel;
import com.twilio.voice.Voice;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;


/**
 * TwilioProgrammableVoicePlugin
 */
public class TwilioProgrammableVoicePlugin implements FlutterPlugin, ActivityAware {
    static String TAG = "TwilioProgrammableVoicePlugin";
    private final LogLevel voiceLogLevel = LogLevel.ERROR;
    final String CALL_STATUS_EVENT_CHANNEL_NAME = "twilio_programmable_voice/call_status";

    private MethodChannel channel;
    private final TwilioProgrammableVoice twilioProgrammableVoice = new TwilioProgrammableVoice();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "twilio_programmable_voice");
        channel.setMethodCallHandler(new MethodCallHandlerImpl(twilioProgrammableVoice));
        twilioProgrammableVoice.setChannel(channel);
        twilioProgrammableVoice.setCallStatusEventChannelWrapper(new EventChannel(flutterPluginBinding.getBinaryMessenger(), CALL_STATUS_EVENT_CHANNEL_NAME));
        Voice.setLogLevel(voiceLogLevel);

    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.twilioProgrammableVoice.setActivity(binding.getActivity());
        this.twilioProgrammableVoice.registerVoiceReceiver();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.twilioProgrammableVoice.setActivity(null);
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.twilioProgrammableVoice.setActivity(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivity() {
        this.twilioProgrammableVoice.setActivity(null);
        twilioProgrammableVoice.setCallStatusEventChannelWrapper(null);
        twilioProgrammableVoice.setChannel(null);
    }
}
