package com.mikronet.voucher.data.model

/**
 * كرت اشتراك Hotspot واحد.
 */
data class Voucher(
    val id: String = "",
    val username: String = "",
    val password: String = "",
    val profile: String = "",        // اسم البروفايل في MikroTik
    val price: String = "",          // مثلاً "10"
    val validity: String = "",       // مثلاً "30 يوم" أو "24 ساعة"
    val createdAt: Long = System.currentTimeMillis(),
    val routerId: String = "",
    val createdBy: String = "",
    val used: Boolean = false
)
