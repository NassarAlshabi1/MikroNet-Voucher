package com.mikronet.voucher.mikrotik

import com.mikronet.voucher.data.model.Voucher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** بيانات الاتصال بالراوتر. */
data class RouterCredentials(
    val host: String,
    val port: Int = 8728,
    val username: String,
    val password: String
)

/** بروفايل Hotspot كما يقرأه من الراوتر. */
data class HotspotProfile(
    val name: String,
    val rateLimit: String = "",
    val sessionTimeout: String = ""
)

/**
 * خدمة عالية المستوى للتعامل مع Hotspot في MikroTik عبر RouterOsClient.
 * كل الدوال تعمل على Dispatchers.IO.
 */
class HotspotService {

    /** يختبر الاتصال ويعيد اسم الراوتر (identity) عند النجاح. */
    suspend fun testConnection(cred: RouterCredentials): Result<String> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول — تحقق من المستخدم/كلمة المرور"))
                }
                val reply = client.talk(listOf("/system/identity/print"))
                val name = reply.firstOrNull { it.type == "!re" }
                    ?.attributes?.get("name") ?: "MikroTik"
                Result.success(name)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    /** يجلب قائمة بروفايلات Hotspot المتاحة. */
    suspend fun getProfiles(cred: RouterCredentials): Result<List<HotspotProfile>> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val reply = client.talk(listOf("/ip/hotspot/user/profile/print"))
                val profiles = reply.filter { it.type == "!re" }.map {
                    HotspotProfile(
                        name = it.attributes["name"] ?: "",
                        rateLimit = it.attributes["rate-limit"] ?: "",
                        sessionTimeout = it.attributes["session-timeout"] ?: ""
                    )
                }.filter { it.name.isNotBlank() }
                Result.success(profiles)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    /**
     * يولّد [quantity] مستخدم Hotspot على الراوتر ضمن البروفايل المحدد،
     * ويعيد قائمة الكروت المولّدة.
     */
    suspend fun generateVouchers(
        cred: RouterCredentials,
        profileName: String,
        quantity: Int,
        userLength: Int,
        passLength: Int,
        priceLabel: String = "",
        validityLabel: String = "",
        comment: String = "MikroNet"
    ): Result<List<Voucher>> = withContext(Dispatchers.IO) {
        val client = RouterOsClient()
        try {
            client.connect(cred.host, cred.port)
            if (!client.login(cred.username, cred.password)) {
                return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
            }

            val vouchers = mutableListOf<Voucher>()
            for (i in 0 until quantity) {
                val username = randomCode(userLength)
                val password = randomCode(passLength)

                val reply = client.talk(
                    listOf(
                        "/ip/hotspot/user/add",
                        "=name=$username",
                        "=password=$password",
                        "=profile=$profileName",
                        "=comment=$comment"
                    )
                )
                val err = reply.firstOrNull { it.type == "!trap" }?.errorMessage()
                if (err != null) {
                    return@withContext Result.failure(Exception("خطأ أثناء توليد الكرت: $err"))
                }

                vouchers.add(
                    Voucher(
                        username = username,
                        password = password,
                        profile = profileName,
                        price = priceLabel,
                        validity = validityLabel
                    )
                )
            }
            Result.success(vouchers)
        } catch (e: Exception) {
            Result.failure(e)
        } finally {
            client.close()
        }
    }

    // ============ أدوات ============

    /** توليد كود عشوائي (أحرف صغيرة + أرقام، بدون أحرف ملتبسة). */
    private fun randomCode(length: Int): String {
        val chars = "abcdefghijkmnpqrstuvwxyz23456789"
        val sb = StringBuilder()
        repeat(length.coerceIn(3, 16)) {
            sb.append(chars[(chars.indices).random()])
        }
        return sb.toString()
    }
}
