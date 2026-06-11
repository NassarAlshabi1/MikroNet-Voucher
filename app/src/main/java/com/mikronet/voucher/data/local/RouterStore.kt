package com.mikronet.voucher.data.local

import android.content.Context
import com.mikronet.voucher.mikrotik.RouterCredentials

/**
 * تخزين محلي بسيط لبيانات الراوتر (اتصال مباشر، بدون سيرفر).
 * ملاحظة أمنية: للإنتاج يُفضّل تشفيرها عبر EncryptedSharedPreferences.
 */
class RouterStore(context: Context) {

    private val prefs = context.getSharedPreferences("router_prefs", Context.MODE_PRIVATE)

    fun save(name: String, cred: RouterCredentials) {
        prefs.edit()
            .putString(KEY_NAME, name)
            .putString(KEY_HOST, cred.host)
            .putInt(KEY_PORT, cred.port)
            .putString(KEY_USER, cred.username)
            .putString(KEY_PASS, cred.password)
            .apply()
    }

    fun isConfigured(): Boolean = !prefs.getString(KEY_HOST, null).isNullOrBlank()

    fun getName(): String = prefs.getString(KEY_NAME, "") ?: ""

    fun getCredentials(): RouterCredentials? {
        val host = prefs.getString(KEY_HOST, null) ?: return null
        return RouterCredentials(
            host = host,
            port = prefs.getInt(KEY_PORT, 8728),
            username = prefs.getString(KEY_USER, "") ?: "",
            password = prefs.getString(KEY_PASS, "") ?: ""
        )
    }

    fun clear() = prefs.edit().clear().apply()

    companion object {
        private const val KEY_NAME = "name"
        private const val KEY_HOST = "host"
        private const val KEY_PORT = "port"
        private const val KEY_USER = "user"
        private const val KEY_PASS = "pass"
    }
}
