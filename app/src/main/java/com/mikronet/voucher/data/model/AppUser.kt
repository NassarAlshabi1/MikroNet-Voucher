package com.mikronet.voucher.data.model

/**
 * يمثّل المستخدم (المشرف/البائع) المسجّل في التطبيق.
 */
data class AppUser(
    val uid: String = "",
    val email: String = "",
    val fullName: String = "",
    val role: String = ROLE_ADMIN,
    val createdAt: Long = System.currentTimeMillis()
) {
    companion object {
        const val ROLE_ADMIN = "ADMIN"
        const val ROLE_RESELLER = "RESELLER"
    }
}
