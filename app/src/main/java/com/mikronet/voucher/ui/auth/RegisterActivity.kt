package com.mikronet.voucher.ui.auth

import android.content.Intent
import android.os.Bundle
import android.util.Patterns
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.mikronet.voucher.R
import com.mikronet.voucher.data.repository.AuthRepository
import com.mikronet.voucher.databinding.ActivityRegisterBinding
import com.mikronet.voucher.ui.dashboard.DashboardActivity
import kotlinx.coroutines.launch

class RegisterActivity : AppCompatActivity() {

    private lateinit var binding: ActivityRegisterBinding
    private val authRepo = AuthRepository()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityRegisterBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.btnRegister.setOnClickListener { doRegister() }
        binding.tvGoLogin.setOnClickListener { finish() }
    }

    private fun doRegister() {
        val name = binding.etName.text?.toString()?.trim().orEmpty()
        val email = binding.etEmail.text?.toString()?.trim().orEmpty()
        val password = binding.etPassword.text?.toString().orEmpty()
        val confirm = binding.etConfirm.text?.toString().orEmpty()

        if (name.isEmpty()) {
            binding.tilName.error = getString(R.string.field_required); return
        }
        binding.tilName.error = null

        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            binding.tilEmail.error = getString(R.string.invalid_email); return
        }
        binding.tilEmail.error = null

        if (password.length < 6) {
            binding.tilPassword.error = getString(R.string.password_short); return
        }
        binding.tilPassword.error = null

        if (password != confirm) {
            binding.tilConfirm.error = getString(R.string.password_mismatch); return
        }
        binding.tilConfirm.error = null

        setLoading(true)
        lifecycleScope.launch {
            val result = authRepo.register(name, email, password)
            setLoading(false)
            result.onSuccess {
                Toast.makeText(this@RegisterActivity, "تم إنشاء الحساب بنجاح", Toast.LENGTH_SHORT).show()
                startActivity(Intent(this@RegisterActivity, DashboardActivity::class.java))
                finishAffinity()
            }.onFailure {
                Toast.makeText(this@RegisterActivity, it.message ?: "فشل إنشاء الحساب", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun setLoading(loading: Boolean) {
        binding.progress.visibility = if (loading) View.VISIBLE else View.GONE
        binding.btnRegister.isEnabled = !loading
    }
}
