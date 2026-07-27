package com.archonex.converter

import android.app.ActivityManager
import android.content.Context
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the capacity probe channel used by `integration_test/capacity_probe_test.dart`.
 *
 * None of this is reachable from the product UI. It exists because the two
 * numbers that decide how large a file the app can handle — the ART heap
 * ceiling and free internal storage — have no Dart API, and because the byte
 * transfer that actually breaks on large results can only be reproduced by
 * pushing a real array across a real channel.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "archonex/capacity"
        const val METHOD_DEVICE_REPORT = "deviceReport"
        const val METHOD_PROBE_TRANSFER = "probeByteTransfer"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_DEVICE_REPORT -> result.success(deviceReport())

                // Receiving the argument as a ByteArray is the whole point: it
                // allocates on the ART heap exactly the way file_picker's
                // saveFile does, so the size at which this fails is the size at
                // which saving fails.
                METHOD_PROBE_TRANSFER -> {
                    val bytes = call.arguments as? ByteArray
                    result.success(bytes?.size?.toLong() ?: -1L)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun deviceReport(): Map<String, Any?> {
        val activityManager =
            getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)

        val runtime = Runtime.getRuntime()
        val stat = StatFs(Environment.getDataDirectory().path)

        return mapOf(
            // The ART heap ceiling. A byte[] above this throws OutOfMemoryError
            // however much RAM the device actually has.
            "memoryClassMb" to activityManager.memoryClass,
            "largeMemoryClassMb" to activityManager.largeMemoryClass,
            "totalRamBytes" to memoryInfo.totalMem,
            "availableRamBytes" to memoryInfo.availMem,
            "lowMemory" to memoryInfo.lowMemory,
            "runtimeMaxHeapBytes" to runtime.maxMemory(),
            "freeInternalStorageBytes" to stat.availableBytes,
            "totalInternalStorageBytes" to stat.totalBytes,
        )
    }
}
