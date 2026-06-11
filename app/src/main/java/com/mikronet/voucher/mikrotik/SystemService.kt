package com.mikronet.voucher.mikrotik

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** كل ما يهمّنا من إحصائيات الراوتر دفعة واحدة. */
data class RouterStats(
    val identity: String = "",
    val model: String = "",
    val version: String = "",
    val uptime: String = "",
    val cpuLoad: Int = 0,              // %
    val cpuCount: Int = 1,
    val cpuFrequency: String = "",
    val freeMemory: Long = 0,
    val totalMemory: Long = 0,
    val freeHddSpace: Long = 0,
    val totalHddSpace: Long = 0,
    val temperature: String = "—",     // °C (أحياناً غير متاح)
    val voltage: String = "—",         // V
    val activeUsers: Int = 0,
    val totalUsers: Int = 0,
    val rxBitsPerSecond: Long = 0,     // إجمالي حركة الـ WAN (أول واجهة ether)
    val txBitsPerSecond: Long = 0
) {
    val memoryUsedPercent: Int
        get() = if (totalMemory == 0L) 0 else (((totalMemory - freeMemory) * 100) / totalMemory).toInt()

    val diskUsedPercent: Int
        get() = if (totalHddSpace == 0L) 0 else (((totalHddSpace - freeHddSpace) * 100) / totalHddSpace).toInt()
}

/**
 * خدمة قراءة الحالة العامة للراوتر (لشاشة لوحة التحكم).
 */
class SystemService {

    suspend fun fetchAll(cred: RouterCredentials): Result<RouterStats> =
        withContext(Dispatchers.IO) {
            val client = RouterOsClient()
            try {
                client.connect(cred.host, cred.port)
                if (!client.login(cred.username, cred.password)) {
                    return@withContext Result.failure(Exception("فشل تسجيل الدخول"))
                }

                // 1) /system/identity
                val identity = client.talk(listOf("/system/identity/print"))
                    .firstOrNull { it.type == "!re" }?.attributes?.get("name") ?: "MikroTik"

                // 2) /system/resource
                val res = client.talk(listOf("/system/resource/print"))
                    .firstOrNull { it.type == "!re" }?.attributes ?: emptyMap()

                // 3) /system/health (قد لا يُدعم على CHR — نتجاهل الخطأ)
                val health = try {
                    client.talk(listOf("/system/health/print"))
                        .firstOrNull { it.type == "!re" }?.attributes ?: emptyMap()
                } catch (_: Exception) { emptyMap() }

                // 4) عدد المتصلين النشطين في Hotspot
                val active = try {
                    client.talk(listOf("/ip/hotspot/active/print", "=count-only="))
                        .firstOrNull { it.type == "!done" }?.attributes?.get("ret")?.toIntOrNull() ?: 0
                } catch (_: Exception) { 0 }

                // 5) إجمالي مستخدمي Hotspot
                val total = try {
                    client.talk(listOf("/ip/hotspot/user/print", "=count-only="))
                        .firstOrNull { it.type == "!done" }?.attributes?.get("ret")?.toIntOrNull() ?: 0
                } catch (_: Exception) { 0 }

                // 6) traffic لأول واجهة Ethernet
                val (rx, tx) = try {
                    fetchFirstEthTraffic(client)
                } catch (_: Exception) { 0L to 0L }

                val stats = RouterStats(
                    identity = identity,
                    model = res["board-name"] ?: res["platform"] ?: "—",
                    version = res["version"] ?: "—",
                    uptime = res["uptime"] ?: "—",
                    cpuLoad = res["cpu-load"]?.toIntOrNull() ?: 0,
                    cpuCount = res["cpu-count"]?.toIntOrNull() ?: 1,
                    cpuFrequency = res["cpu-frequency"] ?: "",
                    freeMemory = res["free-memory"]?.toLongOrNull() ?: 0L,
                    totalMemory = res["total-memory"]?.toLongOrNull() ?: 0L,
                    freeHddSpace = res["free-hdd-space"]?.toLongOrNull() ?: 0L,
                    totalHddSpace = res["total-hdd-space"]?.toLongOrNull() ?: 0L,
                    temperature = health["temperature"]?.let { "$it°C" } ?: "—",
                    voltage = health["voltage"]?.let { "${it}V" } ?: "—",
                    activeUsers = active,
                    totalUsers = total,
                    rxBitsPerSecond = rx,
                    txBitsPerSecond = tx
                )
                Result.success(stats)
            } catch (e: Exception) {
                Result.failure(e)
            } finally {
                client.close()
            }
        }

    /** يقرأ سرعة الحركة (rx/tx bits/s) لأول واجهة ether. */
    private fun fetchFirstEthTraffic(client: RouterOsClient): Pair<Long, Long> {
        // ابحث عن أول واجهة Ethernet (running)
        val ifaceList = client.talk(listOf("/interface/print", "?type=ether"))
            .filter { it.type == "!re" }
        val iface = ifaceList.firstOrNull { it.attributes["running"] == "true" }
            ?: ifaceList.firstOrNull()
            ?: return 0L to 0L
        val name = iface.attributes["name"] ?: return 0L to 0L

        // /interface/monitor-traffic إرسال once=
        val reply = client.talk(
            listOf("/interface/monitor-traffic", "=interface=$name", "=once=")
        )
        val data = reply.firstOrNull { it.type == "!re" }?.attributes ?: emptyMap()
        val rx = data["rx-bits-per-second"]?.toLongOrNull() ?: 0L
        val tx = data["tx-bits-per-second"]?.toLongOrNull() ?: 0L
        return rx to tx
    }
}
