package com.mikronet.voucher.data.model

/**
 * بروفايل Hotspot في MikroTik (يحدد السرعة/المدة/السعر).
 */
data class Profile(
    val id: String = "",
    val name: String = "",            // اسم البروفايل في MikroTik
    val price: String = "",
    val validity: String = "",
    val routerId: String = ""
)
