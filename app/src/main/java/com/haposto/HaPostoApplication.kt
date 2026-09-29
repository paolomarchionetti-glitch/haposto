package com.haposto

import android.app.Application
import com.haposto.platform.notifications.HaPostoNotifications

class HaPostoApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AppDependencies.init(this)
        HaPostoNotifications.createChannels(this)
        AppDependencies.startBackgroundServices(this)
    }
}
