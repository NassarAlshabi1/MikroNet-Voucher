package com.mikronet.voucher

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.mikronet.voucher.data.repository.AuthRepository
import com.mikronet.voucher.ui.auth.LoginActivity
import com.mikronet.voucher.ui.dashboard.DashboardActivity

/**
 * شاشة الإقلاع / الموجّه:
 * إذا كان المستخدم مسجّلاً → لوحة التحكم، وإلا → تسجيل الدخول.
 */
class MainActivity : AppCompatActivity() {

    private val authRepo = AuthRepository()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val target = if (authRepo.isLoggedIn()) {
            DashboardActivity::class.java
        } else {
            LoginActivity::class.java
        }
        startActivity(Intent(this, target))
        finish()
    }
}
