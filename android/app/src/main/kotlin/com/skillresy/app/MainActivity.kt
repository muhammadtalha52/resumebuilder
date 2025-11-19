package com.skillresy.app

import android.content.Context
import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var audioManager: AudioManager? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Configure audio settings for better recording compatibility
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager?

        // Use MODE_NORMAL for flutter_sound compatibility
        audioManager?.mode = AudioManager.MODE_NORMAL
    }

    override fun onResume() {
        super.onResume()
        // Keep audio mode normal when app resumes
        audioManager?.mode = AudioManager.MODE_NORMAL
    }

    override fun onPause() {
        super.onPause()
        // Reset audio mode to normal when app is paused
        audioManager?.mode = AudioManager.MODE_NORMAL
    }
}