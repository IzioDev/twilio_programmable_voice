package fr.izio.twilio_programmable_voice_example;

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback;
// import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin;
// import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService;
import com.github.cloudwebrtc.flutter_callkeep.FlutterCallkeepPlugin;

public class Application extends FlutterApplication implements PluginRegistrantCallback {
    @Override
    public void onCreate() {
        super.onCreate();
        // FlutterFirebaseMessagingService.setPluginRegistrant(this);
    }

    @Override
    public void registerWith(PluginRegistry registry) {
        // FirebaseMessagingPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
        FlutterCallkeepPlugin.registerWith(registry.registrarFor("com.github.cloudwebrtc.flutter_callkeep.FlutterCallkeepPlugin"));
    }
}
