package com.mikronet.voucher.ui.voucher

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.ArrayAdapter
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.mikronet.voucher.R
import com.mikronet.voucher.data.local.RouterStore
import com.mikronet.voucher.data.model.Voucher
import com.mikronet.voucher.data.repository.SaleRecord
import com.mikronet.voucher.data.repository.SalesRepository
import com.mikronet.voucher.databinding.ActivityAddByProfileBinding
import com.mikronet.voucher.mikrotik.HotspotProfile
import com.mikronet.voucher.mikrotik.HotspotService
import com.mikronet.voucher.mikrotik.UserManagerService
import kotlinx.coroutines.launch
import java.util.Date

/**
 * شاشة توليد كروت بحسب البروفايل (اتصال مباشر بالراوتر).
 * تدعم نظامين: Hotspot المحلي و User Manager (RADIUS).
 */
class AddByProfileActivity : AppCompatActivity() {

    private enum class GenMode { HOTSPOT, USER_MANAGER }

    private lateinit var binding: ActivityAddByProfileBinding
    private val service = HotspotService()
    private val umService = UserManagerService()
    private val salesRepo = SalesRepository(this)
    private lateinit var store: RouterStore

    private var mode: GenMode = GenMode.HOTSPOT
    private var profiles: List<HotspotProfile> = emptyList()
    private var selectedProfile: HotspotProfile? = null
    private var umProfiles: List<UserManagerService.UmProfile> = emptyList()
    private var selectedUmProfile: UserManagerService.UmProfile? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAddByProfileBinding.inflate(layoutInflater)
        setContentView(binding.root)
        store = RouterStore(this)

        binding.toolbar.setNavigationOnClickListener { finish() }
        binding.btnGenerate.setOnClickListener { onGenerateClicked() }
        binding.toggleSystem.addOnButtonCheckedListener { _, checkedId, isChecked ->
            if (isChecked) {
                mode = if (checkedId == R.id.btnUmMode) GenMode.USER_MANAGER else GenMode.HOTSPOT
                loadProfiles()
            }
        }

        loadProfiles()
    }

    private fun loadProfiles() {
        when (mode) {
            GenMode.HOTSPOT -> loadHotspotProfiles()
            GenMode.USER_MANAGER -> loadUmProfiles()
        }
    }

    private fun loadHotspotProfiles() {
        val cred = store.getCredentials() ?: run {
            Toast.makeText(this, "أعدّ الراوتر أولاً", Toast.LENGTH_LONG).show()
            finish(); return
        }

        binding.tvStatus.setTextColor(getColor(R.color.text_secondary))
        binding.tvStatus.text = "جاري تحميل البروفايلات من الراوتر..."
        setLoading(true)

        lifecycleScope.launch {
            val result = service.getProfiles(cred)
            if (mode != GenMode.HOTSPOT) return@launch // تغيّر الوضع أثناء التحميل
            setLoading(false)
            result.onSuccess { list ->
                profiles = list
                if (list.isEmpty()) {
                    binding.tvStatus.setTextColor(getColor(R.color.brand_warning))
                    binding.tvStatus.text = "لا توجد بروفايلات Hotspot على الراوتر"
                    return@onSuccess
                }
                showHotspotProfiles(list)
            }.onFailure {
                if (mode == GenMode.HOTSPOT) {
                    binding.tvStatus.setTextColor(getColor(R.color.brand_error))
                    binding.tvStatus.text = "تعذّر التحميل: ${it.message}"
                }
            }
        }
    }

    private fun showHotspotProfiles(list: List<HotspotProfile>) {
        val names = list.map { it.name }
        val adapter = ArrayAdapter(
            this,
            android.R.layout.simple_list_item_1,
            names
        )
        binding.spinnerProfile.setAdapter(adapter)
        binding.spinnerProfile.setOnItemClickListener { _, _, position, _ ->
            selectedProfile = profiles.getOrNull(position)
        }
        // اختيار افتراضي للأول
        selectedProfile = list.first()
        binding.spinnerProfile.setText(list.first().name, false)
        binding.tvStatus.setTextColor(getColor(R.color.text_secondary))
        binding.tvStatus.text = "تم تحميل ${list.size} بروفايل"
    }

    private fun loadUmProfiles() {
        val cred = store.getCredentials() ?: run {
            Toast.makeText(this, "أعدّ الراوتر أولاً", Toast.LENGTH_LONG).show()
            finish(); return
        }

        binding.tvStatus.setTextColor(getColor(R.color.text_secondary))
        binding.tvStatus.text = "جاري تحميل بروفايلات اليوزرمنجر من الراوتر..."
        setLoading(true)

        lifecycleScope.launch {
            val result = umService.getProfiles(cred)
            if (mode != GenMode.USER_MANAGER) return@launch // تغيّر الوضع أثناء التحميل
            setLoading(false)
            result.onSuccess { list ->
                umProfiles = list
                if (list.isEmpty()) {
                    binding.tvStatus.setTextColor(getColor(R.color.brand_warning))
                    binding.tvStatus.text = "لا توجد بروفايلات User Manager على الراوتر — أضف بروفايلات أولاً"
                    return@onSuccess
                }
                val names = list.map { it.name }
                val adapter = ArrayAdapter(
                    this@AddByProfileActivity,
                    android.R.layout.simple_list_item_1,
                    names
                )
                binding.spinnerProfile.setAdapter(adapter)
                binding.spinnerProfile.setOnItemClickListener { _, _, position, _ ->
                    selectedUmProfile = umProfiles.getOrNull(position)
                }
                // اختيار افتراضي للأول
                selectedUmProfile = list.first()
                binding.spinnerProfile.setText(list.first().name, false)
                binding.tvStatus.setTextColor(getColor(R.color.text_secondary))
                binding.tvStatus.text = "تم تحميل ${list.size} بروفايل يوزرمنجر"
            }.onFailure {
                binding.tvStatus.setTextColor(getColor(R.color.brand_error))
                binding.tvStatus.text = "تعذّر التحميل: ${it.message}"
            }
        }
    }

    private fun onGenerateClicked() {
        val profileName: String = when (mode) {
            GenMode.HOTSPOT -> selectedProfile?.name ?: run {
                Toast.makeText(this, "اختر بروفايلاً أولاً", Toast.LENGTH_SHORT).show(); return
            }
            GenMode.USER_MANAGER -> selectedUmProfile?.name ?: run {
                Toast.makeText(this, "اختر بروفايلاً أولاً", Toast.LENGTH_SHORT).show(); return
            }
        }
        val qty = binding.etQuantity.text?.toString()?.toIntOrNull() ?: 0
        val userLen = binding.etUserLen.text?.toString()?.toIntOrNull() ?: 6
        val passLen = binding.etPassLen.text?.toString()?.toIntOrNull() ?: 6
        val price = binding.etPrice.text?.toString()?.toDoubleOrNull() ?: 0.0
        val validity = binding.etValidity.text?.toString()?.trim() ?: ""

        if (qty !in 1..500) {
            Toast.makeText(this, "الكمية يجب أن تكون بين 1 و 500", Toast.LENGTH_SHORT).show(); return
        }
        if (userLen !in 4..16 || passLen !in 4..16) {
            Toast.makeText(this, "الطول يجب أن يكون بين 4 و 16", Toast.LENGTH_SHORT).show(); return
        }

        val cred = store.getCredentials() ?: return
        setLoading(true)
        binding.voucherContainer.removeAllViews()
        binding.tvResultsTitle.visibility = View.GONE
        binding.tvStatus.setTextColor(getColor(R.color.text_secondary))
        binding.tvStatus.text = "جاري إنشاء $qty كرت على الراوتر..."

        lifecycleScope.launch {
            val result = if (mode == GenMode.USER_MANAGER) {
                umService.generateVouchers(
                    cred = cred,
                    profileName = profileName,
                    quantity = qty,
                    userLength = userLen,
                    passLength = passLen,
                    priceLabel = if (price > 0) "$price د.ل." else "",
                    validityLabel = validity
                )
            } else {
                service.generateVouchers(
                    cred = cred,
                    profileName = profileName,
                    quantity = qty,
                    userLength = userLen,
                    passLength = passLen,
                    priceLabel = if (price > 0) "$price د.ل." else "",
                    validityLabel = validity
                )
            }
            setLoading(false)
            result.onSuccess { vouchers ->
                binding.tvStatus.setTextColor(getColor(R.color.brand_success))
                binding.tvStatus.text = "✔ تم توليد ${vouchers.size} كرت بنجاح"
                showResults(vouchers)

                val sale = SaleRecord(
                    profile = profileName,
                    quantity = qty,
                    totalAmount = price * qty,
                    note = validity,
                    routerName = store.getName(),
                    createdAt = Date()
                )
                salesRepo.saveSale(sale)
            }.onFailure {
                binding.tvStatus.setTextColor(getColor(R.color.brand_error))
                binding.tvStatus.text = "✕ ${it.message}"
            }
        }
    }

    private fun showResults(vouchers: List<Voucher>) {
        binding.tvResultsTitle.visibility = View.VISIBLE
        binding.voucherContainer.removeAllViews()
        val inflater = LayoutInflater.from(this)
        for (v in vouchers) {
            val itemView = inflater.inflate(R.layout.item_voucher, binding.voucherContainer, false)
            itemView.findViewById<TextView>(R.id.tvUsername).text = "User: ${v.username}"
            itemView.findViewById<TextView>(R.id.tvPassword).text = "Pass: ${v.password}"
            itemView.findViewById<TextView>(R.id.tvProfile).text = v.profile
            binding.voucherContainer.addView(itemView)
        }
    }

    private fun setLoading(loading: Boolean) {
        binding.progress.visibility = if (loading) View.VISIBLE else View.GONE
        binding.btnGenerate.isEnabled = !loading
    }
}
