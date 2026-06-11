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
import kotlinx.coroutines.launch
import java.util.Date

/**
 * شاشة توليد كروت Hotspot بحسب البروفايل (اتصال مباشر بالراوتر).
 */
class AddByProfileActivity : AppCompatActivity() {

    private lateinit var binding: ActivityAddByProfileBinding
    private val service = HotspotService()
    private val salesRepo = SalesRepository()
    private lateinit var store: RouterStore

    private var profiles: List<HotspotProfile> = emptyList()
    private var selectedProfile: HotspotProfile? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAddByProfileBinding.inflate(layoutInflater)
        setContentView(binding.root)
        store = RouterStore(this)

        binding.toolbar.setNavigationOnClickListener { finish() }
        binding.btnGenerate.setOnClickListener { onGenerateClicked() }

        loadProfiles()
    }

    private fun loadProfiles() {
        val cred = store.getCredentials() ?: run {
            Toast.makeText(this, "أعدّ الراوتر أولاً", Toast.LENGTH_LONG).show()
            finish(); return
        }

        binding.tvStatus.setTextColor(getColor(R.color.text_secondary))
        binding.tvStatus.text = "جاري تحميل البروفايلات من الراوتر..."
        setLoading(true)

        lifecycleScope.launch {
            val result = service.getProfiles(cred)
            setLoading(false)
            result.onSuccess { list ->
                profiles = list
                if (list.isEmpty()) {
                    binding.tvStatus.setTextColor(getColor(R.color.brand_warning))
                    binding.tvStatus.text = "لا توجد بروفايلات Hotspot على الراوتر"
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
                    selectedProfile = profiles[position]
                }
                // اختيار افتراضي للأول
                selectedProfile = list.first()
                binding.spinnerProfile.setText(list.first().name, false)
                binding.tvStatus.text = "تم تحميل ${list.size} بروفايل"
            }.onFailure {
                binding.tvStatus.setTextColor(getColor(R.color.brand_error))
                binding.tvStatus.text = "تعذّر التحميل: ${it.message}"
            }
        }
    }

    private fun onGenerateClicked() {
        val profile = selectedProfile ?: run {
            Toast.makeText(this, "اختر بروفايلاً أولاً", Toast.LENGTH_SHORT).show(); return
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
            val result = service.generateVouchers(
                cred = cred,
                profileName = profile.name,
                quantity = qty,
                userLength = userLen,
                passLength = passLen,
                priceLabel = if (price > 0) "$price د.ل." else "",
                validityLabel = validity
            )
            setLoading(false)
            result.onSuccess { vouchers ->
                binding.tvStatus.setTextColor(getColor(R.color.brand_success))
                binding.tvStatus.text = "✔ تم توليد ${vouchers.size} كرت بنجاح"
                showResults(vouchers)

                val sale = SaleRecord(
                    profile = profile.name,
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
