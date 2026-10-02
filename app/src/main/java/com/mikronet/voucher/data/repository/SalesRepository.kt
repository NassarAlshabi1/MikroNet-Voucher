package com.mikronet.voucher.data.repository

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.util.Date
import java.util.UUID

data class SaleRecord(
    val id: String = "",
    val profile: String = "",
    val quantity: Int = 0,
    val totalAmount: Double = 0.0,
    val note: String = "",
    val routerName: String = "",
    val createdAt: Date = Date(),
    val userId: String = ""
)

/**
 * حفظ وسجلّ المبيعات **محلياً** على الجهاز (SharedPreferences بصيغة JSON)
 * سجل محلي بالكامل على الجهاز.
 */
class SalesRepository(private val context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** يحفظ عملية بيع في السجل المحلي ويعيد معرّفها. */
    suspend fun saveSale(sale: SaleRecord): Result<String> = withContext(Dispatchers.IO) {
        try {
            val id = if (sale.id.isNotBlank()) sale.id else UUID.randomUUID().toString()
            val record = JSONObject().apply {
                put("id", id)
                put("profile", sale.profile)
                put("quantity", sale.quantity)
                put("totalAmount", sale.totalAmount)
                put("note", sale.note)
                put("routerName", sale.routerName)
                put("createdAt", sale.createdAt.time)
                put("userId", sale.userId)
            }

            val arr = JSONArray(prefs.getString(KEY_SALES, "[]") ?: "[]")
            val out = JSONArray()
            out.put(record)
            for (i in 0 until arr.length()) out.put(arr.getJSONObject(i))

            // احتفظ بآخر MAX_RECORDS عملية فقط
            val trimmed = JSONArray()
            val count = minOf(out.length(), MAX_RECORDS)
            for (i in 0 until count) trimmed.put(out.getJSONObject(i))

            prefs.edit().putString(KEY_SALES, trimmed.toString()).apply()
            Result.success(id)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /** يقرأ سجل المبيعات المحلي (الأحدث أولاً). */
    suspend fun getSales(): Result<List<SaleRecord>> = withContext(Dispatchers.IO) {
        try {
            val arr = JSONArray(prefs.getString(KEY_SALES, "[]") ?: "[]")
            val sales = mutableListOf<SaleRecord>()
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                sales.add(
                    SaleRecord(
                        id = o.optString("id", ""),
                        profile = o.optString("profile", ""),
                        quantity = o.optInt("quantity", 0),
                        totalAmount = o.optDouble("totalAmount", 0.0),
                        note = o.optString("note", ""),
                        routerName = o.optString("routerName", ""),
                        createdAt = Date(o.optLong("createdAt", System.currentTimeMillis())),
                        userId = o.optString("userId", "")
                    )
                )
            }
            Result.success(sales)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    companion object {
        private const val PREFS_NAME = "mikronet_sales"
        private const val KEY_SALES = "sales_json"
        private const val MAX_RECORDS = 500
    }
}
