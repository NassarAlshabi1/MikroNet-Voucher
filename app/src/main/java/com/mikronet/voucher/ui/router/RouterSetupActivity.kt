package com.mikronet.voucher.ui.router

import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.mikronet.voucher.data.local.RouterStore
import com.mikronet.voucher.databinding.ActivityRouterSetupBinding
import com.mikronet.voucher.mikrotik.HotspotService
import com.mikronet.voucher.mikrotik.RouterCredentials
import kotlinx.coroutines.launch

class RouterSetupActivity : AppCompatActivity() {

    private lateinit var binding: ActivityRouterSetupBinding
    private val service = HotspotService()
    private lateinit var store: RouterStore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityRouterSetupBinding.inflate(layoutInflater)
        setContentView(binding.root)
        store = RouterStore(this)

        binding.toolbar.setNavigationOnClickListener { finish() }

        // تعبئة البيانات المحفوظة إن وُجدت
        store.getCredentials()?.let { cred ->
            binding.etName.setText(store.getName())
            binding.etHost.setText(cred.host)
            binding.etPort.setText(cred.port.toString())
            binding.etUser.setText(cred.username)
            binding.etPass.setText(cred.password)
        }

        binding.btnTest.setOnClickListener { testConnection() }
        binding.btnSave.setOnClickListener { saveRouter() }
    }

    private fun readCredentials(): RouterCredentials? {
        val host = binding.etHost.text?.toString()?.trim().orEmpty()
        val portStr = binding.etPort.text?.toString()?.trim().orEmpty()
        val user = binding.etUser.text?.toString()?.trim().orEmpty()
        val pass = binding.etPass.text?.toString().orEmpty()

        if (host.isEmpty()) { binding.tilHost.error = getString(com.mikronet.voucher.R.string.field_required); return null }
        binding.tilHost.error = null
        val port = portStr.toIntOrNull() ?: 8728
        if (user.isEmpty()) { binding.tilUser.error = getString(com.mikronet.voucher.R.string.field_required); return null }
        binding.tilUser.error = null

        return RouterCredentials(host, port, user, pass)
    }

    private fun testConnection() {
        val cred = readCredentials() ?: return
        setLoading(true)
        binding.tvStatus.text = ""
        lifecycleScope.launch {
            val result = service.testConnection(cred)
            setLoading(false)
            result.onSuccess { name ->
                binding.tvStatus.setTextColor(getColor(com.mikronet.voucher.R.color.brand_success))
                binding.tvStatus.text = "${getString(com.mikronet.voucher.R.string.connection_success)} $name ✔"
            }.onFailure {
                binding.tvStatus.setTextColor(getColor(com.mikronet.voucher.R.color.brand_error))
                binding.tvStatus.text = "✕ ${it.message}"
            }
        }
    }

    private fun saveRouter() {
        val cred = readCredentials() ?: return
        val name = binding.etName.text?.toString()?.trim().orEmpty().ifEmpty { "راوتر" }
        store.save(name, cred)
        Toast.makeText(this, "تم حفظ بيانات الراوتر", Toast.LENGTH_SHORT).show()
        finish()
    }

    private fun setLoading(loading: Boolean) {
        binding.progress.visibility = if (loading) View.VISIBLE else View.GONE
        binding.btnTest.isEnabled = !loading
        binding.btnSave.isEnabled = !loading
    }
}
