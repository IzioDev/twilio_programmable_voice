package fr.izio.twilio_programmable_voice;

import android.content.Intent;

import androidx.annotation.NonNull;

import com.twilio.voice.LogLevel;
import com.twilio.voice.Voice;

import fr.izio.twilio_programmable_voice.fcm.MessagingService;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

/**
 * TwilioProgrammableVoicePlugin
 */
public class TwilioProgrammableVoicePlugin implements FlutterPlugin, ActivityAware {
    private final LogLevel voiceLogLevel = LogLevel.DEBUG;
    final String CALL_STATUS_EVENT_CHANNEL_NAME = "twilio_programmable_voice/call_status";


    private MethodChannel channel;
    private final TwilioProgrammableVoice twilioProgrammableVoice = new TwilioProgrammableVoice();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "twilio_programmable_voice");
        channel.setMethodCallHandler(new MethodCallHandlerImpl(twilioProgrammableVoice));
        twilioProgrammableVoice.setChannel(channel);
        twilioProgrammableVoice.setEventChannel(new EventChannel(flutterPluginBinding.getBinaryMessenger(), CALL_STATUS_EVENT_CHANNEL_NAME));
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

        Intent service = new Intent(binding.getActivity().getApplicationContext(), MessagingService.class);
        binding.getActivity().startService(service);
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
        this.twilioProgrammableVoice.unregisterVoiceReceiver();
        twilioProgrammableVoice.setEventChannel(null);
        twilioProgrammableVoice.setChannel(null);
    }
}
