package com.mikronet.voucher.ui.dashboard

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.auth.FirebaseAuth
import com.mikronet.voucher.R
import com.mikronet.voucher.data.local.RouterStore
import com.mikronet.voucher.data.repository.AuthRepository
import com.mikronet.voucher.databinding.ActivityDashboardBinding
import com.mikronet.voucher.mikrotik.SystemService
import com.mikronet.voucher.ui.auth.LoginActivity
import com.mikronet.voucher.ui.backup.BackupActivity
import com.mikronet.voucher.ui.hotspot.HotspotUsersActivity
import com.mikronet.voucher.ui.interfaces.InterfaceControlActivity
import com.mikronet.voucher.ui.maintenance.MaintenanceActivity
import com.mikronet.voucher.ui.router.RouterSetupActivity
import com.mikronet.voucher.ui.voucher.AddByProfileActivity
import com.mikronet.voucher.util.Formatters
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DashboardActivity : AppCompatActivity() {

    private lateinit var binding: ActivityDashboardBinding
    private val authRepo = AuthRepository()
    private lateinit var routerStore: RouterStore
    private val systemService = SystemService()
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private var statsJob: Job? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityDashboardBinding.inflate(layoutInflater)
        setContentView(binding.root)
        routerStore = RouterStore(this)

        val email = FirebaseAuth.getInstance().currentUser?.email
        val name = email?.substringBefore("@")?.replaceFirstChar { it.uppercase() } ?: "مشرف"
        binding.tvGreeting.text = "مرحباً، $name"

        binding.btnAddByProfile.setOnClickListener {
            if (!routerStore.isConfigured()) {
                Toast.makeText(this, "أعدّ بيانات الراوتر أولاً", Toast.LENGTH_LONG).show()
                startActivity(Intent(this, RouterSetupActivity::class.java))
            } else {
                startActivity(Intent(this, AddByProfileActivity::class.java))
            }
        }

        binding.btnManageRouter.setOnClickListener {
            startActivity(Intent(this, RouterSetupActivity::class.java))
        }

        binding.btnLogout.setOnClickListener {
            authRepo.logout()
            startActivity(Intent(this, LoginActivity::class.java))
            finishAffinity()
        }

        binding.btnHotspotUsers.setOnClickListener {
            if (!routerStore.isConfigured()) {
                Toast.makeText(this, "أعدّ بيانات الراوتر أولاً", Toast.LENGTH_LONG).show()
                startActivity(Intent(this, RouterSetupActivity::class.java))
            } else {
                startActivity(Intent(this, HotspotUsersActivity::class.java))
            }
        }

        binding.btnBackup.setOnClickListener {
            if (!routerStore.isConfigured()) {
                Toast.makeText(this, "أعدّ بيانات الراوتر أولاً", Toast.LENGTH_LONG).show()
                startActivity(Intent(this, RouterSetupActivity::class.java))
            } else {
                startActivity(Intent(this, BackupActivity::class.java))
            }
        }

        binding.btnMaintenance.setOnClickListener {
            if (!routerStore.isConfigured()) {
                Toast.makeText(this, "أعدّ بيانات الراوتر أولاً", Toast.LENGTH_LONG).show()
                startActivity(Intent(this, RouterSetupActivity::class.java))
            } else {
                startActivity(Intent(this, MaintenanceActivity::class.java))
            }
        }

        binding.btnInterfaceControl.setOnClickListener {
            if (!routerStore.isConfigured()) {
                Toast.makeText(this, "أعدّ بيانات الراوتر أولاً", Toast.LENGTH_LONG).show()
                startActivity(Intent(this, RouterSetupActivity::class.java))
            } else {
                startActivity(Intent(this, InterfaceControlActivity::class.java))
            }
        }
    }

    override fun onResume() {
        super.onResume()
        updateRouterStatus()
        startAutoRefresh()
    }

    override fun onPause() {
        super.onPause()
        statsJob?.cancel()
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    private fun updateRouterStatus() {
        binding.tvRouterStatus.text = if (routerStore.isConfigured()) {
            val cred = routerStore.getCredentials()!!
            "${routerStore.getName()} • ${cred.host}"
        } else {
            getString(R.string.no_router)
        }
    }

    private fun startAutoRefresh() {
        statsJob?.cancel()
        statsJob = scope.launch {
            while (true) {
                refreshStats()
                delay(5000)
            }
        }
    }

    private suspend fun refreshStats() {
        if (!routerStore.isConfigured()) return
        val cred = routerStore.getCredentials() ?: return

        val result = systemService.fetchAll(cred)
        result.onSuccess { stats ->
            binding.tvTemp.text = stats.temperature
            binding.tvCpu.text = "${stats.cpuLoad}%"
            binding.tvVoltage.text = stats.voltage
            binding.tvMemory.text = Formatters.formatPercentWithTotal(
                stats.totalMemory - stats.freeMemory,
                stats.totalMemory
            )
            binding.tvUptime.text = stats.uptime
            binding.tvNetwork.text = Formatters.formatBitrate(
                stats.rxBitsPerSecond.coerceAtLeast(stats.txBitsPerSecond)
            )
            binding.tvDisk.text = Formatters.formatPercentWithTotal(
                stats.totalHddSpace - stats.freeHddSpace,
                stats.totalHddSpace
            )
            binding.tvActiveUsers.text = stats.activeUsers.toString()

            val timeStr = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
            binding.tvStatsUpdateTime.text = "آخر تحديث: $timeStr"
        }
    }
}
