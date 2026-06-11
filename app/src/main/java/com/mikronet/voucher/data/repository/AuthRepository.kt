package com.mikronet.voucher.data.repository

import com.mikronet.voucher.data.model.AppUser
import com.mikronet.voucher.util.Constants
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await

/**
 * يدير تسجيل الدخول/إنشاء الحساب عبر Firebase Auth،
 * ويحفظ بيانات المستخدم في Firestore.
 */
class AuthRepository(
    private val auth: FirebaseAuth = FirebaseAuth.getInstance(),
    private val db: FirebaseFirestore = FirebaseFirestore.getInstance()
) {

    val currentUserId: String?
        get() = auth.currentUser?.uid

    fun isLoggedIn(): Boolean = auth.currentUser != null

    fun logout() = auth.signOut()

    /** تسجيل دخول بالبريد وكلمة المرور */
    suspend fun login(email: String, password: String): Result<Unit> = try {
        auth.signInWithEmailAndPassword(email.trim(), password).await()
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    /** إنشاء حساب جديد + حفظ ملف المستخدم في Firestore */
    suspend fun register(
        fullName: String,
        email: String,
        password: String
    ): Result<Unit> = try {
        val result = auth.createUserWithEmailAndPassword(email.trim(), password).await()
        val uid = result.user?.uid ?: throw IllegalStateException("فشل إنشاء المستخدم")

        val appUser = AppUser(
            uid = uid,
            email = email.trim(),
            fullName = fullName.trim(),
            role = AppUser.ROLE_ADMIN
        )
        db.collection(Constants.COL_USERS).document(uid).set(appUser).await()
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }

    /** إرسال رابط إعادة تعيين كلمة المرور */
    suspend fun resetPassword(email: String): Result<Unit> = try {
        auth.sendPasswordResetEmail(email.trim()).await()
        Result.success(Unit)
    } catch (e: Exception) {
        Result.failure(e)
    }
}
