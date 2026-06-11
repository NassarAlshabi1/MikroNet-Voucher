package com.mikronet.voucher.mikrotik

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class HotspotUser(
    val id: String = "",
    val name: String = "",
    val password: String = "",
    val profile: String = "",
    val comment: String = "",
    val disabled: Boolean = false,
    val uptime: String = "",
    val bytesIn: Long = 0,
    val bytesOut: Long = 0
)

class HotspotManagerService {

    suspend fun listUsers(cred: RouterCredentials): Result<List<HotspotUser>> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val reply = client.talk(listOf("/ip/hotspot/user/print"))
                val users = reply.filter { it.type == "!re" }.map { s ->
                    HotspotUser(
                        id = s.attributes[".id"] ?: "",
                        name = s.attributes["name"] ?: "",
                        password = s.attributes["password"] ?: "",
                        profile = s.attributes["profile"] ?: "",
                        comment = s.attributes["comment"] ?: "",
                        disabled = s.attributes["disabled"] == "true",
                        uptime = s.attributes["uptime"] ?: "",
                        bytesIn = s.attributes["bytes-in"]?.toLongOrNull() ?: 0,
                        bytesOut = s.attributes["bytes-out"]?.toLongOrNull() ?: 0
                    )
                }
                Result.success(users)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    suspend fun addUser(cred: RouterCredentials, name: String, password: String, profile: String, comment: String = ""): Result<Unit> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val cmd = mutableListOf("/ip/hotspot/user/add", "=name=$name", "=password=$password", "=profile=$profile")
                if (comment.isNotBlank()) cmd.add("=comment=$comment")
                val reply = client.talk(cmd)
                val err = reply.firstOrNull { it.type == "!trap" }?.errorMessage()
                if (err != null) Result.failure(Exception(err))
                else Result.success(Unit)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    suspend fun removeUser(cred: RouterCredentials, id: String): Result<Unit> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val reply = client.talk(listOf("/ip/hotspot/user/remove", "=.id=$id"))
                val err = reply.firstOrNull { it.type == "!trap" }?.errorMessage()
                if (err != null) Result.failure(Exception(err))
                else Result.success(Unit)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    suspend fun setUserEnabled(cred: RouterCredentials, id: String, enable: Boolean): Result<Unit> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val cmd = if (enable) "/ip/hotspot/user/enable" else "/ip/hotspot/user/disable"
                val reply = client.talk(listOf(cmd, "=.id=$id"))
                val err = reply.firstOrNull { it.type == "!trap" }?.errorMessage()
                if (err != null) Result.failure(Exception(err))
                else Result.success(Unit)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }
}
