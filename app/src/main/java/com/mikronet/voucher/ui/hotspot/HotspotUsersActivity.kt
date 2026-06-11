package com.mikronet.voucher.ui.hotspot

import android.app.AlertDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.mikronet.voucher.R
import com.mikronet.voucher.data.local.RouterStore
import com.mikronet.voucher.databinding.ActivityHotspotUsersBinding
import com.mikronet.voucher.databinding.DialogAddUserBinding
import com.mikronet.voucher.databinding.ItemHotspotUserBinding
import com.mikronet.voucher.mikrotik.HotspotManagerService
import com.mikronet.voucher.mikrotik.HotspotProfile
import com.mikronet.voucher.mikrotik.HotspotService
import com.mikronet.voucher.mikrotik.HotspotUser
import com.mikronet.voucher.util.Formatters
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import android.widget.ArrayAdapter

class HotspotUsersActivity : AppCompatActivity() {

    private lateinit var binding: ActivityHotspotUsersBinding
    private lateinit var routerStore: RouterStore
    private val manager = HotspotManagerService()
    private val hotspotService = HotspotService()
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private val users = mutableListOf<HotspotUser>()
    private lateinit var adapter: UserAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityHotspotUsersBinding.inflate(layoutInflater)
        setContentView(binding.root)
        routerStore = RouterStore(this)

        adapter = UserAdapter(users) { user, action ->
            when (action) {
                UserAction.TOGGLE -> toggleUser(user)
                UserAction.DELETE -> confirmDelete(user)
            }
        }
        binding.rvUsers.layoutManager = LinearLayoutManager(this)
        binding.rvUsers.adapter = adapter

        binding.btnBack.setOnClickListener { finish() }
        binding.fabAddUser.setOnClickListener { showAddDialog() }

        loadUsers()
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    private fun loadUsers() {
        val cred = routerStore.getCredentials() ?: return
        binding.fabAddUser.hide()
        scope.launch {
            val result = withContext(Dispatchers.IO) { manager.listUsers(cred) }
            result.onSuccess { list ->
                users.clear(); users.addAll(list); adapter.notifyDataSetChanged()
                binding.tvUserCount.text = "${list.size} مستخدم"
                binding.fabAddUser.show()
            }.onFailure {
                Toast.makeText(this@HotspotUsersActivity, "فشل تحميل المستخدمين: ${it.message}", Toast.LENGTH_LONG).show()
                finish()
            }
        }
    }

    private fun toggleUser(user: HotspotUser) {
        val cred = routerStore.getCredentials() ?: return
        scope.launch {
            val result = withContext(Dispatchers.IO) { manager.setUserEnabled(cred, user.id, user.disabled) }
            result.onSuccess { loadUsers() }
            result.onFailure { Toast.makeText(this@HotspotUsersActivity, "فشل: ${it.message}", Toast.LENGTH_SHORT).show() }
        }
    }

    private fun confirmDelete(user: HotspotUser) {
        AlertDialog.Builder(this)
            .setTitle("حذف مستخدم")
            .setMessage("هل تريد حذف المستخدم ${user.name}؟")
            .setPositiveButton("حذف") { _, _ ->
                val cred = routerStore.getCredentials() ?: return@setPositiveButton
                scope.launch {
                    val result = withContext(Dispatchers.IO) { manager.removeUser(cred, user.id) }
                    result.onSuccess { loadUsers() }
                    result.onFailure { Toast.makeText(this@HotspotUsersActivity, "فشل الحذف: ${it.message}", Toast.LENGTH_SHORT).show() }
                }
            }
            .setNegativeButton("إلغاء", null)
            .show()
    }

    private fun showAddDialog() {
        val cred = routerStore.getCredentials() ?: return
        val dialogBinding = DialogAddUserBinding.inflate(layoutInflater)
        val dialog = AlertDialog.Builder(this)
            .setTitle("إضافة مستخدم Hotspot")
            .setView(dialogBinding.root)
            .setPositiveButton("إضافة", null)
            .setNegativeButton("إلغاء", null)
            .create()

        scope.launch {
            val profiles = withContext(Dispatchers.IO) { hotspotService.getProfiles(cred) }
            profiles.onSuccess { list ->
                val names = list.map { it.name }.toTypedArray()
                val adapter = ArrayAdapter(this@HotspotUsersActivity, android.R.layout.simple_dropdown_item_1line, names)
                dialogBinding.spinnerProfile.setAdapter(adapter)
            }
        }

        dialog.setOnShowListener {
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
                val name = dialogBinding.etName.text.toString().trim()
                val pass = dialogBinding.etPassword.text.toString().trim()
                val profile = dialogBinding.spinnerProfile.text.toString().trim()
                if (name.isEmpty() || pass.isEmpty() || profile.isEmpty()) {
                    Toast.makeText(this, "جميع الحقول مطلوبة", Toast.LENGTH_SHORT).show()
                    return@setOnClickListener
                }
                scope.launch {
                    val result = withContext(Dispatchers.IO) { manager.addUser(cred, name, pass, profile) }
                    result.onSuccess { dialog.dismiss(); loadUsers() }
                    result.onFailure { Toast.makeText(this@HotspotUsersActivity, "فشل: ${it.message}", Toast.LENGTH_SHORT).show() }
                }
            }
        }
        dialog.show()
    }
}

enum class UserAction { TOGGLE, DELETE }

class UserAdapter(
    private val users: List<HotspotUser>,
    private val onAction: (HotspotUser, UserAction) -> Unit
) : RecyclerView.Adapter<UserAdapter.ViewHolder>() {

    class ViewHolder(val bind: ItemHotspotUserBinding) : RecyclerView.ViewHolder(bind.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val bind = ItemHotspotUserBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(bind)
    }

    override fun getItemCount() = users.size

    override fun onBindViewHolder(holder: ViewHolder, pos: Int) {
        val u = users[pos]
        holder.bind.tvUserName.text = u.name
        holder.bind.tvUserProfile.text = "البروفايل: ${u.profile}"
        holder.bind.tvUserTraffic.text = "↑ ${Formatters.formatBytes(u.bytesOut)} ↓ ${Formatters.formatBytes(u.bytesIn)}"

        if (u.disabled) {
            holder.bind.tvUserStatus.text = "معطل"
            holder.bind.tvUserStatus.setBackgroundResource(R.drawable.bg_circle_white_trans)
        } else {
            holder.bind.tvUserStatus.text = "نشط"
            holder.bind.tvUserStatus.setBackgroundResource(R.drawable.bg_circle_accent)
        }

        holder.itemView.setOnClickListener { onAction(u, UserAction.TOGGLE) }
        holder.itemView.setOnLongClickListener {
            onAction(u, UserAction.DELETE)
            true
        }
    }
}
