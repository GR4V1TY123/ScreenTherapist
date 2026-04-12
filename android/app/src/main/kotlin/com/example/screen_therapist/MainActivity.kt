package com.example.screen_therapist

import android.app.AppOpsManager
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "com.example.screen_therapist/daily_usage"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"hasUsagePermission" -> result.success(hasUsageStatsPermission())

					"openUsageSettings" -> {
						openUsageAccessSettings()
						result.success(true)
					}

					"getDailyUsageStats" -> {
						if (!hasUsageStatsPermission()) {
							result.error(
								"PERMISSION_DENIED",
								"Usage access permission is required.",
								null
							)
							return@setMethodCallHandler
						}

						val startTime = call.argument<Number>("startTime")?.toLong()
						val endTime = call.argument<Number>("endTime")?.toLong()
						if (startTime == null || endTime == null) {
							result.error(
								"INVALID_ARGUMENTS",
								"startTime and endTime are required.",
								null
							)
							return@setMethodCallHandler
						}

						Thread {
							try {
								val data = DailyUsageCollector(applicationContext).collect(startTime, endTime)
								runOnUiThread { result.success(data) }
							} catch (e: Exception) {
								runOnUiThread {
									result.error("COLLECTION_FAILED", e.message, null)
								}
							}
						}.start()
					}

					else -> result.notImplemented()
				}
			}
	}

	private fun openUsageAccessSettings() {
		val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
		intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
		startActivity(intent)
	}

	private fun hasUsageStatsPermission(): Boolean {
		val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
		val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			appOps.unsafeCheckOpNoThrow(
				AppOpsManager.OPSTR_GET_USAGE_STATS,
				Process.myUid(),
				packageName
			)
		} else {
			appOps.checkOpNoThrow(
				AppOpsManager.OPSTR_GET_USAGE_STATS,
				Process.myUid(),
				packageName
			)
		}

		return mode == AppOpsManager.MODE_ALLOWED
	}
}
