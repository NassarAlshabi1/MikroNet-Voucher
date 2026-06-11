package com.mikronet.voucher.data.repository

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import kotlinx.coroutines.tasks.await
import java.util.Date

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

class SalesRepository {

    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    private val collection = db.collection("sales")

    suspend fun saveSale(sale: SaleRecord): Result<String> {
        return try {
            val doc = collection.document()
            val data = hashMapOf(
                "profile" to sale.profile,
                "quantity" to sale.quantity,
                "totalAmount" to sale.totalAmount,
                "note" to sale.note,
                "routerName" to sale.routerName,
                "createdAt" to sale.createdAt,
                "userId" to (auth.currentUser?.uid ?: "")
            )
            doc.set(data).await()
            Result.success(doc.id)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getSales(): Result<List<SaleRecord>> {
        return try {
            val snapshot = collection
                .whereEqualTo("userId", auth.currentUser?.uid ?: "")
                .orderBy("createdAt", Query.Direction.DESCENDING)
                .limit(100)
                .get()
                .await()
            val sales = snapshot.documents.map { doc ->
                SaleRecord(
                    id = doc.id,
                    profile = doc.getString("profile") ?: "",
                    quantity = doc.getLong("quantity")?.toInt() ?: 0,
                    totalAmount = doc.getDouble("totalAmount") ?: 0.0,
                    note = doc.getString("note") ?: "",
                    routerName = doc.getString("routerName") ?: "",
                    createdAt = doc.getDate("createdAt") ?: Date(),
                    userId = doc.getString("userId") ?: ""
                )
            }
            Result.success(sales)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
