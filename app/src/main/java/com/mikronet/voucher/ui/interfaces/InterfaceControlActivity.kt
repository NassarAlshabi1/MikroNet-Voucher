package com.mikronet.voucher.ui.interfaces

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.mikronet.voucher.R
import com.mikronet.voucher.databinding.ActivityInterfacesBinding
import com.mikronet.voucher.databinding.ItemInterfaceBinding
import com.mikronet.voucher.data.local.RouterStore
import com.mikronet.voucher.mikrotik.InterfaceService
import com.mikronet.voucher.mikrotik.RouterInterface
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class InterfaceControlActivity : AppCompatActivity() {

    private lateinit var binding: ActivityInterfacesBinding
    private lateinit var routerStore: RouterStore
    private val service = InterfaceService()
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private val ifaces = mutableListOf<RouterInterface>()
    private lateinit var adapter: InterfaceAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityInterfacesBinding.inflate(layoutInflater)
        setContentView(binding.root)
        routerStore = RouterStore(this)

        adapter = InterfaceAdapter(ifaces) { iface ->
            val cred = routerStore.getCredentials() ?: return@InterfaceAdapter
            scope.launch {
                val result = withContext(Dispatchers.IO) { service.setInterfaceEnabled(cred, iface.id, iface.disabled) }
                result.onSuccess { loadInterfaces() }
                result.onFailure { Toast.makeText(this@InterfaceControlActivity, "فشل: ${it.message}", Toast.LENGTH_SHORT).show() }
            }
        }
        binding.rvInterfaces.layoutManager = LinearLayoutManager(this)
        binding.rvInterfaces.adapter = adapter

        binding.btnBack.setOnClickListener { finish() }
        loadInterfaces()
    }

    override fun onDestroy() {
        super.onDestroy(); scope.cancel()
    }

    private fun loadInterfaces() {
        val cred = routerStore.getCredentials() ?: return
        scope.launch {
            val result = withContext(Dispatchers.IO) { service.listInterfaces(cred) }
            result.onSuccess { list -> ifaces.clear(); ifaces.addAll(list); adapter.notifyDataSetChanged() }
            result.onFailure { Toast.makeText(this@InterfaceControlActivity, "فشل تحميل الواجهات: ${it.message}", Toast.LENGTH_LONG).show(); finish() }
        }
    }
}

class InterfaceAdapter(
    private val ifaces: List<RouterInterface>,
    private val onClick: (RouterInterface) -> Unit
) : RecyclerView.Adapter<InterfaceAdapter.ViewHolder>() {

    class ViewHolder(val bind: ItemInterfaceBinding) : RecyclerView.ViewHolder(bind.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val bind = ItemInterfaceBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(bind)
    }

    override fun getItemCount() = ifaces.size

    override fun onBindViewHolder(holder: ViewHolder, pos: Int) {
        val iface = ifaces[pos]
        holder.bind.tvInterfaceName.text = iface.name
        holder.bind.tvInterfaceType.text = iface.type

        if (iface.disabled) {
            holder.bind.tvInterfaceStatus.text = "معطل"
            holder.bind.tvInterfaceStatus.setBackgroundResource(R.drawable.bg_circle_white_trans)
        } else if (iface.running) {
            holder.bind.tvInterfaceStatus.text = "نشط"
            holder.bind.tvInterfaceStatus.setBackgroundResource(R.drawable.bg_circle_accent)
        } else {
            holder.bind.tvInterfaceStatus.text = "متوقف"
            holder.bind.tvInterfaceStatus.setBackgroundResource(R.drawable.bg_circle_white_trans)
        }
        holder.itemView.setOnClickListener { onClick(iface) }
    }
}
