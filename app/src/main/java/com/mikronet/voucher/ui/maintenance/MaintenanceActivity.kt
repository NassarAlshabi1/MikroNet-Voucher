package com.mikronet.voucher.ui.maintenance

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.mikronet.voucher.databinding.ActivityMaintenanceBinding
import com.mikronet.voucher.data.local.RouterStore
import com.mikronet.voucher.mikrotik.MaintenanceService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MaintenanceActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMaintenanceBinding
    private lateinit var routerStore: RouterStore
    private val maintenanceService = MaintenanceService()
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMaintenanceBinding.inflate(layoutInflater)
        setContentView(binding.root)
        routerStore = RouterStore(this)

        binding.btnBack.setOnClickListener { finish() }

        binding.btnClearSessions.setOnClickListener { confirmAction("محو جميع الجلسات النشطة؟") { maintenanceService.clearActiveSessions(it) } }
        binding.btnRemoveOld.setOnClickListener { confirmAction("حذف الكروت المنتهية الصلاحية؟") { maintenanceService.removeOldUsers(it) } }
        binding.btnResetUM.setOnClickListener { confirmAction("إعادة بناء قاعدة بيانات User Manager؟") { maintenanceService.resetUserManagerDB(it) } }
    }

    override fun onDestroy() {
        super.onDestroy(); scope.cancel()
    }

    private fun confirmAction(msg: String, action: suspend (com.mikronet.voucher.mikrotik.RouterCredentials) -> Result<String>) {
        val cred = routerStore.getCredentials() ?: run {
            Toast.makeText(this, "الرجاء إعداد الراوتر أولاً", Toast.LENGTH_SHORT).show(); return
        }
        AlertDialog.Builder(this)
            .setTitle("تأكيد")
            .setMessage(msg)
            .setPositiveButton("نعم") { _, _ ->
                scope.launch {
                    val result = withContext(Dispatchers.IO) { action(cred) }
                    result.onSuccess { Toast.makeText(this@MaintenanceActivity, it, Toast.LENGTH_LONG).show() }
                    result.onFailure { Toast.makeText(this@MaintenanceActivity, "فشل: ${it.message}", Toast.LENGTH_LONG).show() }
                }
            }
            .setNegativeButton("إلغاء", null)
            .show()
    }
}
