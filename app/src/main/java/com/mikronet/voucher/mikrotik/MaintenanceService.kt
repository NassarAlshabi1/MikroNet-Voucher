package com.mikronet.voucher.mikrotik

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class MaintenanceService {

    suspend fun clearActiveSessions(cred: RouterCredentials): Result<String> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val reply = client.talk(listOf("/ip/hotspot/active/remove-all"))
                val err = reply.firstOrNull { it.type == "!trap" }?.errorMessage()
                if (err != null) Result.failure(Exception(err))
                else Result.success("تم محو جميع الجلسات النشطة")
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    suspend fun removeOldUsers(cred: RouterCredentials): Result<String> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val users = client.talk(listOf("/ip/hotspot/user/print"))
                var removed = 0
                for (sentence in users) {
                    if (sentence.type == "!re") {
                        val uptime = sentence.attributes["uptime"] ?: ""
                        val limitUptime = sentence.attributes["limit-uptime"] ?: ""
                        val id = sentence.attributes[".id"] ?: ""
                        if (uptime.isNotBlank() && limitUptime.isNotBlank() && id.isNotBlank()) {
                            val reply = client.talk(listOf("/ip/hotspot/user/remove", "=.id=$id"))
                            if (reply.none { it.type == "!trap" }) removed++
                        }
                    }
                }
                Result.success("تم حذف $removed مستخدم منتهي الصلاحية")
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    suspend fun resetUserManagerDB(cred: RouterCredentials): Result<String> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val cmd6 = "/tool/user-manager/database/reset"
                val cmd7 = "/user-manager/database/reset"
                var reply = client.talk(listOf(cmd6))
                if (reply.any { it.type == "!trap" }) {
                    reply = client.talk(listOf(cmd7))
                }
                val err = reply.firstOrNull { it.type == "!trap" }?.errorMessage()
                if (err != null) Result.failure(Exception(err))
                else Result.success("تم إعادة بناء قاعدة بيانات User Manager")
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }
}
