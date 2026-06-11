package com.mikronet.voucher.ui.auth

import android.content.Intent
import android.os.Bundle
import android.util.Patterns
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.mikronet.voucher.data.repository.AuthRepository
import com.mikronet.voucher.databinding.ActivityLoginBinding
import com.mikronet.voucher.ui.dashboard.DashboardActivity
import kotlinx.coroutines.launch

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private val authRepo = AuthRepository()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.btnLogin.setOnClickListener { doLogin() }

        binding.tvGoRegister.setOnClickListener {
            startActivity(Intent(this, RegisterActivity::class.java))
        }

        binding.tvForgot.setOnClickListener { doResetPassword() }
    }

    private fun doLogin() {
        val email = binding.etEmail.text?.toString()?.trim().orEmpty()
        val password = binding.etPassword.text?.toString().orEmpty()

        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            binding.tilEmail.error = getString(com.mikronet.voucher.R.string.invalid_email)
            return
        }
        binding.tilEmail.error = null
        if (password.length < 6) {
            binding.tilPassword.error = getString(com.mikronet.voucher.R.string.password_short)
            return
        }
        binding.tilPassword.error = null

        setLoading(true)
        lifecycleScope.launch {
            val result = authRepo.login(email, password)
            setLoading(false)
            result.onSuccess {
                goToDashboard()
            }.onFailure {
                Toast.makeText(this@LoginActivity, it.message ?: "فشل تسجيل الدخول", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun doResetPassword() {
        val email = binding.etEmail.text?.toString()?.trim().orEmpty()
        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            Toast.makeText(this, "أدخل بريدك الإلكتروني أولاً", Toast.LENGTH_SHORT).show()
            return
        }
        lifecycleScope.launch {
            authRepo.resetPassword(email).onSuccess {
                Toast.makeText(this@LoginActivity, "تم إرسال رابط إعادة التعيين إلى بريدك", Toast.LENGTH_LONG).show()
            }.onFailure {
                Toast.makeText(this@LoginActivity, it.message ?: "تعذر الإرسال", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun goToDashboard() {
        startActivity(Intent(this, DashboardActivity::class.java))
        finishAffinity()
    }

    private fun setLoading(loading: Boolean) {
        binding.progress.visibility = if (loading) View.VISIBLE else View.GONE
        binding.btnLogin.isEnabled = !loading
    }
}
