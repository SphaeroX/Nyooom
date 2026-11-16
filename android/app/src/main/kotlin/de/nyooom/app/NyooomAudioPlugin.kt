package de.nyooom.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.MicrophoneInfo
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AudioEffect
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Raw stereo recording for Nyooom (technik.pdf 4.2, 4.3).
 *
 * Opens AudioRecord with AudioSource.UNPROCESSED when the device reports
 * support, otherwise VOICE_RECOGNITION; 16-bit PCM stereo. AGC, NS and AEC
 * are switched off for the session. Interleaved little-endian PCM blocks are
 * streamed to Dart over the event channel.
 *
 * Method channel `de.nyooom/audio`: getCapabilities, start({sampleRate}), stop.
 * Event channel `de.nyooom/audio_stream`: ByteArray blocks.
 */
class NyooomAudioPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.RequestPermissionsResultListener {

    companion object {
        const val METHOD_CHANNEL = "de.nyooom/audio"
        const val EVENT_CHANNEL = "de.nyooom/audio_stream"
        private const val PERMISSION_REQUEST_CODE = 4711
        private const val TAG = "NyooomAudio"

        /** Block length sent to Dart, in milliseconds. */
        private const val BLOCK_MS = 20
    }

    private lateinit var context: Context
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    private var pendingStart: Pair<StartRequest, MethodChannel.Result>? = null
    private var recorder: AudioRecord? = null
    private var readThread: Thread? = null

    @Volatile
    private var running = false
    private val effects = mutableListOf<AudioEffect>()

    // region FlutterPlugin / ActivityAware

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopRecording()
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    // endregion

    // region Method channel

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> result.success(capabilities())
            "getInputDevices" -> result.success(inputDevices())
            "start" -> {
                val request = StartRequest(
                    call.argument<Int>("sampleRate") ?: 48000,
                    call.argument<Int>("inputDeviceId"),
                )
                if (hasPermission()) {
                    startRecording(request, result)
                } else {
                    requestPermission(request, result)
                }
            }
            "stop" -> {
                stopRecording()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun audioManager() =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private fun unprocessedSupported(): Boolean =
        audioManager().getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED) == "true"

    private fun capabilities(): Map<String, Any> {
        val microphones = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                audioManager().microphones.map(::describe)
            } catch (e: Exception) {
                Log.w(TAG, "getMicrophones failed", e)
                emptyList()
            }
        } else {
            emptyList()
        }
        return mapOf(
            "unprocessedSupported" to unprocessedSupported(),
            "agcAvailable" to AutomaticGainControl.isAvailable(),
            "nsAvailable" to NoiseSuppressor.isAvailable(),
            "aecAvailable" to AcousticEchoCanceler.isAvailable(),
            "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "sdkInt" to Build.VERSION.SDK_INT,
            "microphones" to microphones,
        )
    }

    /** Input devices for the selection (technik.pdf 4.3: external USB microphone). */
    private fun inputDevices(): List<Map<String, Any>> =
        audioManager().getDevices(AudioManager.GET_DEVICES_INPUTS).map { d ->
            mapOf(
                "id" to d.id,
                "name" to d.productName.toString(),
                "type" to d.type,
                "isExternal" to (d.type == AudioDeviceInfo.TYPE_USB_DEVICE ||
                    d.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
                    d.type == AudioDeviceInfo.TYPE_WIRED_HEADSET),
                "channelCounts" to d.channelCounts.toList(),
            )
        }

    private fun describe(info: MicrophoneInfo): String {
        val p = info.position
        val position = if (p == MicrophoneInfo.POSITION_UNKNOWN) {
            "Position unbekannt"
        } else {
            "Position (%.3f, %.3f, %.3f) m".format(p.x, p.y, p.z)
        }
        return "${info.description} [id ${info.id}, Typ ${info.type}, $position]"
    }

    // endregion

    // region Permission

    private fun hasPermission(): Boolean =
        context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    private fun requestPermission(request: StartRequest, result: MethodChannel.Result) {
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("PERMISSION_DENIED", "No activity to request the permission", null)
            return
        }
        if (pendingStart != null) {
            result.error("BUSY", "Permission request already pending", null)
            return
        }
        pendingStart = request to result
        activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val (request, result) = pendingStart ?: return true
        pendingStart = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startRecording(request, result)
        } else {
            result.error("PERMISSION_DENIED", "Microphone permission denied", null)
        }
        return true
    }

    // endregion

    // region Recording

    private fun createRecord(source: Int, sampleRate: Int, bufferBytes: Int): AudioRecord? {
        val record = AudioRecord(
            source,
            sampleRate,
            AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferBytes,
        )
        if (record.state == AudioRecord.STATE_INITIALIZED) return record
        record.release()
        return null
    }

    private fun startRecording(request: StartRequest, result: MethodChannel.Result) {
        val sampleRate = request.sampleRate
        if (running) {
            result.error("ALREADY_RUNNING", "Recording is already running", null)
            return
        }
        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minBuffer <= 0) {
            result.error("INIT_FAILED", "Stereo 16 bit at $sampleRate Hz not supported", null)
            return
        }
        // At least 200 ms of headroom so the Dart side never starves the reader.
        val bufferBytes = maxOf(minBuffer * 4, sampleRate / 5 * 4)

        var record: AudioRecord? = null
        var sourceName = "UNPROCESSED"
        try {
            if (unprocessedSupported()) {
                record = createRecord(MediaRecorder.AudioSource.UNPROCESSED, sampleRate, bufferBytes)
            }
            if (record == null) {
                sourceName = "VOICE_RECOGNITION"
                record = createRecord(MediaRecorder.AudioSource.VOICE_RECOGNITION, sampleRate, bufferBytes)
            }
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
            return
        }
        if (record == null) {
            result.error("INIT_FAILED", "AudioRecord could not be initialized", null)
            return
        }

        var preferredDevice = ""
        request.inputDeviceId?.let { id ->
            val device = audioManager().getDevices(AudioManager.GET_DEVICES_INPUTS)
                .firstOrNull { it.id == id }
            if (device != null && record.setPreferredDevice(device)) {
                preferredDevice = device.productName.toString()
            }
        }

        val session = record.audioSessionId
        val effectStates = mapOf(
            "agc" to disableEffect(AutomaticGainControl.isAvailable()) {
                AutomaticGainControl.create(session)
            },
            "ns" to disableEffect(NoiseSuppressor.isAvailable()) { NoiseSuppressor.create(session) },
            "aec" to disableEffect(AcousticEchoCanceler.isAvailable()) {
                AcousticEchoCanceler.create(session)
            },
        )

        try {
            record.startRecording()
        } catch (e: IllegalStateException) {
            releaseAll(record)
            result.error("INIT_FAILED", e.message, null)
            return
        }
        if (record.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
            releaseAll(record)
            result.error("INIT_FAILED", "AudioRecord did not start (microphone busy?)", null)
            return
        }

        recorder = record
        running = true
        val blockBytes = record.sampleRate * BLOCK_MS / 1000 * record.channelCount * 2
        readThread = Thread({ readLoop(record, blockBytes) }, "NyooomAudioRecord").also { it.start() }

        val activeMicrophones = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                record.activeMicrophones.map(::describe)
            } catch (e: Exception) {
                emptyList()
            }
        } else {
            emptyList()
        }
        Log.i(TAG, "Recording: source=$sourceName rate=${record.sampleRate} effects=$effectStates")
        result.success(
            mapOf(
                "audioSource" to sourceName,
                "sampleRate" to record.sampleRate,
                "channels" to record.channelCount,
                "effects" to effectStates,
                "activeMicrophones" to activeMicrophones,
                "preferredDevice" to preferredDevice,
            ),
        )
    }

    /** Returns "unavailable", "disabled" or "enabled" (could not be switched off). */
    private fun disableEffect(available: Boolean, create: () -> AudioEffect?): String {
        if (!available) return "unavailable"
        val effect = try {
            create()
        } catch (e: Exception) {
            Log.w(TAG, "Effect creation failed", e)
            null
        } ?: return "unavailable"
        effects.add(effect)
        try {
            effect.enabled = false
        } catch (e: Exception) {
            Log.w(TAG, "Effect could not be disabled", e)
        }
        return if (effect.enabled) "enabled" else "disabled"
    }

    private fun readLoop(record: AudioRecord, blockBytes: Int) {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
        val buffer = ByteArray(blockBytes)
        while (running) {
            val read = record.read(buffer, 0, buffer.size)
            if (read > 0) {
                val block = buffer.copyOf(read)
                mainHandler.post { eventSink?.success(block) }
            } else if (read < 0) {
                mainHandler.post { eventSink?.error("READ_FAILED", "AudioRecord.read returned $read", null) }
                break
            }
        }
    }

    private fun stopRecording() {
        if (!running && recorder == null) return
        running = false
        readThread?.join(500)
        readThread = null
        recorder?.let { releaseAll(it) }
        recorder = null
    }

    private fun releaseAll(record: AudioRecord) {
        try {
            if (record.recordingState == AudioRecord.RECORDSTATE_RECORDING) record.stop()
        } catch (e: IllegalStateException) {
            Log.w(TAG, "stop failed", e)
        }
        record.release()
        effects.forEach { it.release() }
        effects.clear()
    }

    // endregion

    // region Event channel

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // endregion
}

/** Arguments of the `start` method. */
private data class StartRequest(val sampleRate: Int, val inputDeviceId: Int?)
