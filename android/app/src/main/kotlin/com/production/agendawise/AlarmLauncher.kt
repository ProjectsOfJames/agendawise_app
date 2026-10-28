package com.production.agendawise

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * Opens the app when an alarm rings while the phone is unlocked and in use.
 *
 * The alarm package rings through a full-screen notification, which Android
 * only turns into a full-screen activity when the screen is off or locked.
 * A second system alarm, set for the same moment, lets this receiver bring
 * the app to the front in the unlocked case. Starting an activity from the
 * background is only allowed once the user has granted "Display over other
 * apps", so nothing happens without it and the notification is used instead.
 */
object AlarmLauncher {
    private const val TAG = "AlarmLauncher"
    private const val ACTION = "com.production.agendawise.LAUNCH_ALARM"

    fun schedule(context: Context, id: Int, atMillis: Long) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = pendingIntent(context, id, PendingIntent.FLAG_UPDATE_CURRENT) ?: return
        val exactAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager.canScheduleExactAlarms()
        if (exactAllowed) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, intent)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, intent)
        }
    }

    fun cancel(context: Context, id: Int) {
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = pendingIntent(context, id, PendingIntent.FLAG_NO_CREATE) ?: return
        alarmManager.cancel(intent)
        intent.cancel()
    }

    private fun pendingIntent(context: Context, id: Int, flags: Int): PendingIntent? {
        val intent = Intent(context, AlarmLaunchReceiver::class.java).setAction(ACTION)
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            flags or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    internal fun launchIfUnlocked(context: Context) {
        if (!Settings.canDrawOverlays(context)) return
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        // Locked or screen-off phones are handled by the full-screen notification.
        if (keyguard != null && keyguard.isKeyguardLocked) return
        val launch = Intent(context, MainActivity::class.java).addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
        )
        try {
            context.startActivity(launch)
        } catch (error: Exception) {
            Log.w(TAG, "Could not open the app for a ringing alarm", error)
        }
    }
}

class AlarmLaunchReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AlarmLauncher.launchIfUnlocked(context)
    }
}
