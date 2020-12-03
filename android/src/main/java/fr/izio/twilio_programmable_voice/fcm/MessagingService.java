package fr.izio.twilio_programmable_voice.fcm;

import android.util.Log;

import androidx.annotation.NonNull;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class MessagingService extends FirebaseMessagingService {
    static String TAG = "MessagingService";
    private String token;

    @Override
    public void onNewToken(@NonNull String s) {
        super.onNewToken(s);
        this.token = s;
    }

    @Override
    public void onMessageReceived(@NonNull RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);
        Log.d(TAG, "RECEIVED : " + remoteMessage.toString());
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Created");
    }
}
