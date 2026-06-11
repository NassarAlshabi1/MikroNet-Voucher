package com.mikronet.voucher.mikrotik

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class RouterInterface(
    val id: String = "",
    val name: String = "",
    val type: String = "",
    val running: Boolean = false,
    val disabled: Boolean = false,
    val comment: String = ""
)

class InterfaceService {

    suspend fun listInterfaces(cred: RouterCredentials): Result<List<RouterInterface>> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val reply = client.talk(listOf("/interface/print"))
                val ifaces = reply.filter { it.type == "!re" }.map { s ->
                    RouterInterface(
                        id = s.attributes[".id"] ?: "",
                        name = s.attributes["name"] ?: "",
                        type = s.attributes["type"] ?: "",
                        running = s.attributes["running"] == "true",
                        disabled = s.attributes["disabled"] == "true",
                        comment = s.attributes["comment"] ?: ""
                    )
                }
                Result.success(ifaces)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    suspend fun setInterfaceEnabled(cred: RouterCredentials, id: String, enable: Boolean): Result<Unit> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val cmd = if (enable) "/interface/enable" else "/interface/disable"
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
