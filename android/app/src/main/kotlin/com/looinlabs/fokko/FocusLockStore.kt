package com.looinlabs.fokko

import android.content.Context

/** 잠금 상태 저장소 (접근성 서비스와 채널이 공유) */
object FocusLockStore {
    private const val PREFS = "focusone_lock"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun selection(c: Context): Set<String> = prefs(c).getStringSet("apps", emptySet()) ?: emptySet()

    fun setSelection(c: Context, apps: Set<String>) = prefs(c).edit().putStringSet("apps", apps).apply()

    fun start(c: Context, sessionId: String, endsAtMs: Long) =
        prefs(c).edit().putString("sessionId", sessionId).putLong("endsAt", endsAtMs).apply()

    fun stop(c: Context) = prefs(c).edit().remove("sessionId").remove("endsAt").apply()

    /** 진행 중(종료 시각 전)이고 목록에 있는 앱이면 막는다 */
    fun isBlocked(c: Context, pkg: String): Boolean {
        val p = prefs(c)
        val endsAt = p.getLong("endsAt", 0L)
        if (endsAt <= System.currentTimeMillis()) return false
        return pkg in selection(c)
    }
}
