package com.mikronet.voucher

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.mikronet.voucher.ui.dashboard.DashboardActivity

/**
 * شاشة الإقلاع: يفتح التطبيق مباشرة على لوحة التحكم
 * (بدون بوابة تسجيل دخول).
 */
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startActivity(Intent(this, DashboardActivity::class.java))
        finish()
    }
}
