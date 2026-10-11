package com.looinlabs.focusone

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focusone/lock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(
                        mapOf(
                            "authorized" to accessibilityEnabled(),
                            "selectedCount" to FocusLockStore.selection(this).size,
                        )
                    )
                    // 접근성 권한은 앱이 직접 켤 수 없다 → 설정 화면으로 안내
                    "authorize" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(accessibilityEnabled())
                    }
                    "listApps" -> result.success(launchableApps())
                    "selection" -> result.success(FocusLockStore.selection(this).toList())
                    "setSelection" -> {
                        @Suppress("UNCHECKED_CAST")
                        FocusLockStore.setSelection(this, (call.argument<List<String>>("apps") ?: emptyList()).toSet())
                        result.success(FocusLockStore.selection(this).size)
                    }
                    "start" -> {
                        val id = call.argument<String>("sessionId")
                        val ends = call.argument<Number>("endsAtMs")?.toLong()
                        if (id == null || ends == null || FocusLockStore.selection(this).isEmpty() || !accessibilityEnabled()) {
                            result.success(false)
                        } else {
                            FocusLockStore.start(this, id, ends)
                            result.success(true)
                        }
                    }
                    "stop" -> {
                        FocusLockStore.stop(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun accessibilityEnabled(): Boolean {
        val me = ComponentName(this, FocusLockAccessibility::class.java).flattenToString()
        val enabled = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
        return TextUtils.SimpleStringSplitter(':').apply { setString(enabled) }.any { it.equals(me, ignoreCase = true) }
    }

    /** 홈 화면에 아이콘이 있는 앱 목록 (자기 자신 제외) */
    private fun launchableApps(): List<Map<String, String>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(intent, 0)
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .filter { it.first != packageName }
            .distinctBy { it.first }
            .sortedBy { it.second }
            .map { mapOf("package" to it.first, "label" to it.second) }
    }
}
