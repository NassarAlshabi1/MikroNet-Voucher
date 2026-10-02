package com.mikronet.voucher.util

import java.util.Locale

object Formatters {

    /** يحوّل بايتات إلى صيغة قابلة للقراءة (KB / MB / GB). */
    fun formatBytes(bytes: Long): String {
        if (bytes <= 0) return "0 B"
        val units = arrayOf("B", "KB", "MB", "GB", "TB")
        var b = bytes.toDouble()
        var i = 0
        while (b >= 1024 && i < units.size - 1) { b /= 1024; i++ }
        return String.format(Locale.US, "%.1f %s", b, units[i])
    }

    /** يحوّل bits/s إلى Kbps/Mbps. */
    fun formatBitrate(bps: Long): String {
        if (bps <= 0) return "0 bps"
        val units = arrayOf("bps", "Kbps", "Mbps", "Gbps")
        var b = bps.toDouble()
        var i = 0
        while (b >= 1000 && i < units.size - 1) { b /= 1000; i++ }
        return String.format(Locale.US, "%.1f %s", b, units[i])
    }

    /** نسبة استخدام الذاكرة/القرص بصيغة "45%" */
    fun formatPercent(used: Long, total: Long): String {
        if (total <= 0) return "—"
        return "${(used * 100 / total)}%"
    }

    /** نسبة مع الحجم الكلي بصيغة "45% (2.3/5.0GB)" */
    fun formatPercentWithTotal(used: Long, total: Long): String {
        if (total <= 0) return "—"
        val pct = used * 100 / total
        return "$pct% (${formatBytes(used)}/${formatBytes(total)})"
    }
}
