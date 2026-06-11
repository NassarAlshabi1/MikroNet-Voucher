package com.mikronet.voucher.data.model

/**
 * راوتر MikroTik مُدار من التطبيق.
 */
data class Router(
    val id: String = "",
    val name: String = "",
    val host: String = "",            // IP أو DDNS
    val apiPort: Int = 8728,
    val username: String = "",
    val owner: String = "",           // uid المالك
    val online: Boolean = false,
    val createdAt: Long = System.currentTimeMillis()
)
