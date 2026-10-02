package com.mikronet.voucher.ui.backup

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.mikronet.voucher.databinding.ActivityBackupBinding
import com.mikronet.voucher.data.local.RouterStore
import com.mikronet.voucher.mikrotik.BackupService
import com.mikronet.voucher.util.Formatters
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class BackupActivity : AppCompatActivity() {

    private lateinit var binding: ActivityBackupBinding
    private lateinit var routerStore: RouterStore
    private val backupService = BackupService()
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityBackupBinding.inflate(layoutInflater)
        setContentView(binding.root)
        routerStore = RouterStore(this)

        binding.btnBack.setOnClickListener { finish() }

        binding.btnCreateBackup.setOnClickListener {
            val cred = routerStore.getCredentials()
            if (cred == null) {
                Toast.makeText(this, "الرجاء إعداد الراوتر أولاً", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val name = binding.etBackupName.text.toString().trim()
            if (name.isEmpty()) {
                binding.tilBackupName.error = "الاسم مطلوب"
                return@setOnClickListener
            }
            binding.tilBackupName.error = null
            binding.btnCreateBackup.isEnabled = false
            binding.btnCreateBackup.text = "جارٍ الإنشاء..."
            scope.launch {
                val result = withContext(Dispatchers.IO) { backupService.createBackup(cred, name) }
                binding.btnCreateBackup.isEnabled = true
                binding.btnCreateBackup.text = "إنشاء النسخة"
                result.onSuccess { Toast.makeText(this@BackupActivity, "تم إنشاء $it", Toast.LENGTH_SHORT).show(); loadBackups() }
                result.onFailure { Toast.makeText(this@BackupActivity, "فشل: ${it.message}", Toast.LENGTH_LONG).show() }
            }
        }

        loadBackups()
    }

    override fun onDestroy() {
        super.onDestroy(); scope.cancel()
    }

    private fun loadBackups() {
        val cred = routerStore.getCredentials() ?: return
        scope.launch {
            val result = withContext(Dispatchers.IO) { backupService.listBackups(cred) }
            result.onSuccess { list ->
                if (list.isEmpty()) binding.tvBackupList.text = "لا توجد نسخ احتياطية"
                else binding.tvBackupList.text = list.joinToString("\n") { "${it.fileName} (${Formatters.formatBytes(it.fileSize.toLongOrNull() ?: 0)})" }
            }
        }
    }
}
