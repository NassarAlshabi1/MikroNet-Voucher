package com.mikronet.voucher.mikrotik

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class RouterBackup(
    val fileName: String = "",
    val fileSize: String = "",
    val creationTime: String = ""
)

class BackupService {

    suspend fun createBackup(cred: RouterCredentials, name: String): Result<String> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val reply = client.talk(listOf("/system/backup/save", "=name=$name"))
                val err = reply.firstOrNull { it.type == "!trap" }?.errorMessage()
                if (err != null) return@withContext Result.failure(Exception(err))
                reply.firstOrNull { it.type == "!done" }
                Result.success("$name.backup")
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    suspend fun listBackups(cred: RouterCredentials): Result<List<RouterBackup>> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }
                val reply = client.talk(listOf("/file/print", "?type=backup"))
                val files = reply.filter { it.type == "!re" }.map { s ->
                    RouterBackup(
                        fileName = s.attributes["name"] ?: "",
                        fileSize = s.attributes["size"] ?: "0",
                        creationTime = s.attributes["creation-time"] ?: ""
                    )
                }.filter { it.fileName.isNotBlank() }
                Result.success(files)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }
}
