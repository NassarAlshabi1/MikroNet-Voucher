package com.mikronet.voucher.data.model

/**
 * أمر يُرسل عبر Firestore ليقرأه السيرفر الوسيط وينفّذه في MikroTik.
 */
data class Command(
    val id: String = "",
    val type: String = "",                       // مثل GENERATE_VOUCHERS
    val routerId: String = "",
    val payload: Map<String, Any> = emptyMap(),
    val status: String = STATUS_PENDING,
    val createdBy: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val resultVoucherIds: List<String> = emptyList(),
    val errorMessage: String? = null
) {
    companion object {
        const val TYPE_GENERATE_VOUCHERS = "GENERATE_VOUCHERS"

        const val STATUS_PENDING = "PENDING"
        const val STATUS_PROCESSING = "PROCESSING"
        const val STATUS_DONE = "DONE"
        const val STATUS_FAILED = "FAILED"
    }
}
