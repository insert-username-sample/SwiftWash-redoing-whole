package com.example.swiftwash_driver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction()) ||
            "android.intent.action.QUICKBOOT_POWERON".equals(intent.getAction())) {

            // Check if driver was previously online
            SharedPreferences prefs = context.getSharedPreferences("driver_prefs", Context.MODE_PRIVATE);
            boolean wasOnline = prefs.getBoolean("was_online", false);
            String driverId = prefs.getString("driver_id", null);

            if (wasOnline && driverId != null) {
                // Restart location service
                Intent serviceIntent = new Intent(context, LocationService.class);
                serviceIntent.putExtra("driverId", driverId);
                serviceIntent.putExtra("isOnline", true);

                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent);
                } else {
                    context.startService(serviceIntent);
                }
            }
        }
    }
}
