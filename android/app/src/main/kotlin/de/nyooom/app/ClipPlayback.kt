package de.nyooom.app

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plays recorded clips (WAV files) for labelling, on its own method channel
 * ("de.nyooom/playback"): playFile(path), stopPlayback(); calls
 * playbackCompleted on the Dart side when a clip has played to its end.
 */
class ClipPlayback(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "de.nyooom/playback"
        const val COMPLETED_METHOD = "playbackCompleted"
    }

    private val channel = MethodChannel(messenger, CHANNEL).also {
        it.setMethodCallHandler(this)
    }
    private val mainHandler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "playFile" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("NO_PATH", "path missing", null)
                    return
                }
                try {
                    play(path)
                    result.success(null)
                } catch (e: Exception) {
                    release()
                    result.error("PLAYBACK_FAILED", e.message, null)
                }
            }
            "stopPlayback" -> {
                release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun play(path: String) {
        release()
        player = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
            )
            setDataSource(path)
            setOnCompletionListener {
                release()
                mainHandler.post { channel.invokeMethod(COMPLETED_METHOD, null) }
            }
            prepare()
            start()
        }
    }

    private fun release() {
        player?.release()
        player = null
    }

    fun dispose() {
        release()
        channel.setMethodCallHandler(null)
    }
}
