package com.looinlabs.focusone

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

/**
 * 집중 중 앱 잠금 (Android). 전면 앱이 잠금 목록에 있으면 FocusOne으로 되돌린다.
 * 잠금 목록·종료 시각은 SharedPreferences에서 직접 읽는다 → Flutter가 죽어도 만료 후엔 막지 않는다.
 * 화면 내용은 읽지 않고 앱 패키지 이름만 본다 (접근성 정책 고지: 설정 화면 안내 문구).
 */
class FocusLockAccessibility : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName) return
        if (!FocusLockStore.isBlocked(this, pkg)) return
        startActivity(
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                .putExtra("blockedPackage", pkg)
        )
    }

    override fun onInterrupt() {}
}
