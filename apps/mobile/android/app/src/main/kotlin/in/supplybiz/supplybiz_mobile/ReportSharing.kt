package `in`.supplybiz.supplybiz_mobile

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

// T-102: only explicit, authenticated CSV downloads reach this private cache.
class ReportSharing(private val activity: FlutterActivity) {
    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "share") { result.notImplemented(); return }
        try {
            val bytes = call.argument<ByteArray>("bytes") ?: error("bytes")
            val id = call.argument<String>("id") ?: error("id")
            require(UUID.fromString(id).toString() == id)
            val from = call.argument<String>("from") ?: error("from")
            val to = call.argument<String>("to") ?: error("to")
            require(Regex("[0-9]{4}-[0-9]{2}-[0-9]{2}").matches(from))
            require(Regex("[0-9]{4}-[0-9]{2}-[0-9]{2}").matches(to))
            val dates = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { isLenient = false; timeZone = TimeZone.getTimeZone("UTC") }
            val start = dates.parse(from) ?: error("from"); val end = dates.parse(to) ?: error("to")
            require(dates.format(start) == from && dates.format(end) == to && !from.startsWith("0000"))
            require(end.time >= start.time && (end.time - start.time) / 86400000 < 366)
            require(bytes.isNotEmpty() && bytes.size <= 8388608 && bytes.size == call.argument<Int>("size"))
            val hash = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
            require(hash == call.argument<String>("sha256"))
            val directory = File(activity.cacheDir, "report_exports")
            require(directory.mkdirs() || directory.isDirectory)
            // Bounded derived artifacts; never touch files outside this dedicated directory.
            directory.listFiles()?.filter { it.isFile && it.lastModified() < System.currentTimeMillis() - 86400000 }?.forEach { it.delete() }
            val file = File(directory, "supplybiz-report-$from-$to-$id.csv")
            directory.listFiles()?.filter { it.isFile && it.name != file.name }?.sortedByDescending { it.lastModified() }?.drop(9)?.forEach { it.delete() }
            file.writeBytes(bytes)
            val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.report_exports", file)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/csv"
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newRawUri("", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            activity.startActivity(Intent.createChooser(intent, null))
            // This acknowledges opening the chooser, never recipient delivery.
            result.success(true)
        } catch (_: Exception) { result.success(false) }
    }
}
