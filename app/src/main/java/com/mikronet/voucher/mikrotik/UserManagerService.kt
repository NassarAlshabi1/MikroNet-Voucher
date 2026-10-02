package com.mikronet.voucher.mikrotik

import com.mikronet.voucher.data.model.Voucher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * خدمة عالية المستوى للتعامل مع نظام User Manager (RADIUS) في MikroTik.
 *
 * تكتشف إصدار RouterOS تلقائياً من /system/resource وتستخدم مجموعة الأوامر المناسبة:
 *  - RouterOS v7: /user-manager/...
 *  - RouterOS v6: /tool/user-manager/... (مع customer)
 *
 * وإذا فشل مسار الإصدار المكتشف، يجرّب المسار الآخر تلقائياً.
 */
class UserManagerService {

    /** بروفايل User Manager كما يقرأه من الراوتر. */
    data class UmProfile(
        val name: String,
        val price: String = "",
        val validity: String = ""
    )

    /** الإصدار الأساسي المكتشف من RouterOS (6 أو 7). */
    private var rosMajor = 7

    /**
     * يختبر الاتصال ويعيد اسم الراوتر (identity) مع الإصدار المكتشف،
     * مثال: "MikroTik-Home (RouterOS v7)".
     */
    suspend fun testConnection(cred: RouterCredentials): Result<String> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول — تحقق من المستخدم/كلمة المرور"))
                }
                detectVersion(client)
                val reply = client.talk(listOf("/system/identity/print"))
                val name = reply.firstOrNull { it.type == "!re" }
                    ?.attributes?.get("name") ?: "MikroTik"
                Result.success("$name (RouterOS v$rosMajor)")
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    /** يجلب قائمة بروفايلات User Manager المتاحة على الراوتر. */
    suspend fun getProfiles(cred: RouterCredentials): Result<List<UmProfile>> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                detectVersion(client)
                var reply = client.talk(listOf(profilesPrintPath()))
                if (reply.any { it.type == "!trap" }) {
                    // فشل مسار الإصدار المكتشف — جرّب مجموعة أوامر الإصدار الآخر
                    rosMajor = if (rosMajor >= 7) 6 else 7
                    reply = client.talk(listOf(profilesPrintPath()))
                }
                val err = reply.firstOrNull { it.type == "!trap" }?.errorMessage()
                if (err != null) {
                    return@withContext Result.failure(
                        Exception("$err — تأكد من تفعيل اليوزرمنجر على الراوتر")
                    )
                }
                val profiles = reply.filter { it.type == "!re" }.map {
                    UmProfile(
                        name = it.attributes["name"] ?: "",
                        price = it.attributes["price"] ?: "",
                        validity = it.attributes["validity"] ?: ""
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
     * يولّد [quantity] كرت User Manager على الراوتر ضمن البروفايل المحدد،
     * ويعيد قائمة الكروت المولّدة.
     *
     * - v6: إضافة مستخدم ثم create-and-activate-profile لتفعيل البروفايل فوراً.
     * - v7: إضافة مستخدم ثم إضافة profile-limitations له.
     */
    suspend fun generateVouchers(
        cred: RouterCredentials,
        profileName: String,
        quantity: Int,
        userLength: Int,
        passLength: Int,
        priceLabel: String = "",
        validityLabel: String = ""
    ): Result<List<Voucher>> = withContext(Dispatchers.IO) {
        val client = RouterOsClient()
        try {
            client.connect(cred.host, cred.port)
            if (!client.login(cred.username, cred.password)) {
                return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
            }
            detectVersion(client)

            val vouchers = mutableListOf<Voucher>()
            for (i in 0 until quantity) {
                val username = randomCode(userLength)
                val password = randomCode(passLength)

                // 1) إضافة مستخدم اليوزرمنجر
                val addReply = client.talk(addUserCmd(username, password))
                var err = addReply.firstOrNull { it.type == "!trap" }?.errorMessage()

                // 2) إسناد البروفايل للكرت (تفعيله)
                if (err == null) {
                    val profReply = client.talk(activateProfileCmd(username, profileName))
                    err = profReply.firstOrNull { it.type == "!trap" }?.errorMessage()
                }

                if (err != null) {
                    return@withContext Result.failure(
                        Exception("خطأ أثناء توليد الكرت ($username): $err")
                    )
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

    // ============ أدوات خاصة ============

    /** يقرأ إصدار RouterOS من /system/resource ويحدد مجموعة الأوامر المناسبة. */
    private fun detectVersion(client: RouterOsClient) {
        val reply = client.talk(listOf("/system/resource/print"))
        val version = reply.firstOrNull { it.type == "!re" }
            ?.attributes?.get("version") ?: ""
        val major = version.trim().substringBefore('.').filter { it.isDigit() }.toIntOrNull()
        if (major != null && major > 0) rosMajor = major
    }

    private fun profilesPrintPath(): String =
        if (rosMajor >= 7) "/user-manager/profile/print"
        else "/tool/user-manager/profile/print"

    /** أمر إضافة مستخدم UM بحسب الإصدار. */
    private fun addUserCmd(name: String, password: String): List<String> =
        if (rosMajor >= 7) {
            listOf(
                "/user-manager/user/add",
                "=name=$name",
                "=password=$password"
            )
        } else {
            listOf(
                "/tool/user-manager/user/add",
                "=customer=$UM_CUSTOMER",
                "=name=$name",
                "=password=$password"
            )
        }

    /** أمر إسناد/تفعيل البروفايل على المستخدم بحسب الإصدار. */
    private fun activateProfileCmd(name: String, profile: String): List<String> =
        if (rosMajor >= 7) {
            listOf(
                "/user-manager/user/profile-limitations/add",
                "=user=$name",
                "=profile=$profile"
            )
        } else {
            listOf(
                "/tool/user-manager/user/create-and-activate-profile",
                "=customer=$UM_CUSTOMER",
                "=name=$name",
                "=profile=$profile"
            )
        }

    /** توليد كود عشوائي (أحرف صغيرة + أرقام، بدون أحرف ملتبسة). */
    private fun randomCode(length: Int): String {
        val chars = "abcdefghijkmnpqrstuvwxyz23456789"
        val sb = StringBuilder()
        repeat(length.coerceIn(3, 16)) {
            sb.append(chars[(chars.indices).random()])
        }
        return sb.toString()
    }

    companion object {
        /** اسم العميل (customer) الافتراضي في User Manager على RouterOS v6. */
        const val UM_CUSTOMER = "admin"
    }
}
