package com.mikronet.voucher.mikrotik

import java.io.BufferedInputStream
import java.io.InputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.security.MessageDigest

/**
 * عميل RouterOS API أصلي (بروتوكول MikroTik الثنائي على المنفذ 8728).
 *
 * يدعم:
 *  - تسجيل الدخول الحديث (RouterOS 6.43+ / 7.x) بإرسال الاسم وكلمة المرور مباشرة.
 *  - تسجيل الدخول القديم (RouterOS < 6.43) بآلية التحدي MD5.
 *
 * ملاحظة: كل العمليات حاجبة (blocking) — استدعها داخل Dispatchers.IO.
 */
class RouterOsClient {

    private var socket: Socket? = null
    private var input: InputStream? = null
    private var output: OutputStream? = null

    /** يفتح اتصال TCP بالراوتر. */
    fun connect(host: String, port: Int = 8728, timeoutMs: Int = 8000) {
        val s = Socket()
        s.connect(InetSocketAddress(host, port), timeoutMs)
        s.soTimeout = timeoutMs
        socket = s
        input = BufferedInputStream(s.getInputStream())
        output = s.getOutputStream()
    }

    /**
     * تسجيل الدخول. يحاول الطريقة الحديثة أولاً، ثم يسقط للطريقة القديمة (MD5).
     * @return true عند النجاح.
     */
    fun login(username: String, password: String): Boolean {
        // الطريقة الحديثة: /login =name= =password=
        var reply = talk(listOf("/login", "=name=$username", "=password=$password"))

        if (reply.any { it.type == "!done" } && reply.none { it.type == "!trap" }) {
            // قد يحتوي !done على =ret= (خادم قديم يطلب التحدي)
            val challenge = reply.firstOrNull { it.attributes.containsKey("ret") }
                ?.attributes?.get("ret")
            if (challenge == null) return true   // نجح مباشرة

            // الطريقة القديمة: حساب استجابة MD5 للتحدي
            val response = computeChallengeResponse(password, challenge)
            reply = talk(
                listOf("/login", "=name=$username", "=response=00$response")
            )
            return reply.any { it.type == "!done" } && reply.none { it.type == "!trap" }
        }

        return false
    }

    /**
     * يرسل جملة (sentence) ويقرأ الرد كاملاً حتى !done.
     * @return قائمة الجُمل المُستقبَلة (!re, !done, !trap ...).
     */
    fun talk(words: List<String>): List<Sentence> {
        writeSentence(words)
        val result = mutableListOf<Sentence>()
        while (true) {
            val sentence = readSentence()
            result.add(sentence)
            if (sentence.type == "!done" || sentence.type == "!fatal") break
        }
        return result
    }

    fun close() {
        try { output?.flush() } catch (_: Exception) {}
        try { socket?.close() } catch (_: Exception) {}
        socket = null; input = null; output = null
    }

    // ============ بروتوكول القراءة/الكتابة ============

    private fun writeSentence(words: List<String>) {
        val out = output ?: throw IllegalStateException("غير متصل")
        for (w in words) {
            val bytes = w.toByteArray(Charsets.UTF_8)
            writeLength(out, bytes.size)
            out.write(bytes)
        }
        writeLength(out, 0) // نهاية الجملة
        out.flush()
    }

    private fun readSentence(): Sentence {
        val words = mutableListOf<String>()
        while (true) {
            val len = readLength()
            if (len == 0) break
            val buf = ByteArray(len)
            var read = 0
            val ins = input ?: throw IllegalStateException("غير متصل")
            while (read < len) {
                val r = ins.read(buf, read, len - read)
                if (r < 0) throw IllegalStateException("انقطع الاتصال")
                read += r
            }
            words.add(String(buf, Charsets.UTF_8))
        }
        return Sentence.parse(words)
    }

    /** ترميز طول الكلمة حسب مواصفة MikroTik. */
    private fun writeLength(out: OutputStream, len: Int) {
        when {
            len < 0x80 -> out.write(len)
            len < 0x4000 -> {
                out.write((len shr 8) or 0x80)
                out.write(len and 0xFF)
            }
            len < 0x200000 -> {
                out.write((len shr 16) or 0xC0)
                out.write((len shr 8) and 0xFF)
                out.write(len and 0xFF)
            }
            len < 0x10000000 -> {
                out.write((len shr 24) or 0xE0)
                out.write((len shr 16) and 0xFF)
                out.write((len shr 8) and 0xFF)
                out.write(len and 0xFF)
            }
            else -> {
                out.write(0xF0)
                out.write((len shr 24) and 0xFF)
                out.write((len shr 16) and 0xFF)
                out.write((len shr 8) and 0xFF)
                out.write(len and 0xFF)
            }
        }
    }

    /** فك ترميز طول الكلمة. */
    private fun readLength(): Int {
        val ins = input ?: throw IllegalStateException("غير متصل")
        val c = ins.read()
        if (c < 0) throw IllegalStateException("انقطع الاتصال")
        return when {
            c and 0x80 == 0x00 -> c
            c and 0xC0 == 0x80 -> ((c and 0x3F) shl 8) + ins.read()
            c and 0xE0 == 0xC0 -> ((c and 0x1F) shl 16) + (ins.read() shl 8) + ins.read()
            c and 0xF0 == 0xE0 -> ((c and 0x0F) shl 24) + (ins.read() shl 16) + (ins.read() shl 8) + ins.read()
            else -> (ins.read() shl 24) + (ins.read() shl 16) + (ins.read() shl 8) + ins.read()
        }
    }

    /** حساب استجابة التحدي MD5 (للنسخ القديمة). */
    private fun computeChallengeResponse(password: String, challengeHex: String): String {
        val challenge = hexToBytes(challengeHex)
        val md = MessageDigest.getInstance("MD5")
        md.update(0)
        md.update(password.toByteArray(Charsets.UTF_8))
        md.update(challenge)
        return bytesToHex(md.digest())
    }

    private fun hexToBytes(hex: String): ByteArray {
        val out = ByteArray(hex.length / 2)
        for (i in out.indices) {
            out[i] = ((Character.digit(hex[i * 2], 16) shl 4) +
                    Character.digit(hex[i * 2 + 1], 16)).toByte()
        }
        return out
    }

    private fun bytesToHex(bytes: ByteArray): String {
        val sb = StringBuilder()
        for (b in bytes) sb.append(String.format("%02x", b))
        return sb.toString()
    }

    /** جملة رد من الراوتر. */
    data class Sentence(
        val type: String,                       // !re / !done / !trap / !fatal
        val attributes: Map<String, String>,    // أزواج المفتاح/القيمة
        val raw: List<String>
    ) {
        companion object {
            fun parse(words: List<String>): Sentence {
                if (words.isEmpty()) return Sentence("", emptyMap(), words)
                val type = words[0]
                val attrs = mutableMapOf<String, String>()
                for (i in 1 until words.size) {
                    val w = words[i]
                    if (w.startsWith("=")) {
                        val rest = w.substring(1)
                        val idx = rest.indexOf('=')
                        if (idx >= 0) {
                            attrs[rest.substring(0, idx)] = rest.substring(idx + 1)
                        } else {
                            attrs[rest] = ""
                        }
                    }
                }
                return Sentence(type, attrs, words)
            }
        }

        fun errorMessage(): String? =
            if (type == "!trap" || type == "!fatal") attributes["message"] ?: "خطأ من الراوتر"
            else null
    }
}
