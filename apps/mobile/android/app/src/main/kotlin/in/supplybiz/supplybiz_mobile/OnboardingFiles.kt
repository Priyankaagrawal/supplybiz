package `in`.supplybiz.supplybiz_mobile

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.view.WindowManager
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

/** SAF selection: no storage permission, retained URI grant, cache copy or filename logging. */
class OnboardingFiles(private val activity: Activity) {
    private val secureOwners = mutableSetOf<String>()
    private var pending: MethodChannel.Result? = null
    fun handle(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "secure" -> {
                val owner = call.argument<String>("owner") ?: "test"
                if (call.argument<Boolean>("enabled") == true) secureOwners.add(owner) else secureOwners.remove(owner)
                if (secureOwners.isNotEmpty())
                    activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                else activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                result.success(null)
            }
            "isSecure" -> result.success(activity.window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE != 0)
            "previewPdf" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null || bytes.size > 5 * 1024 * 1024) { result.error("FILE_INVALID", null, null); return }
                Thread {
                    val file = java.io.File.createTempFile("preview-", ".pdf", activity.cacheDir)
                    try {
                        file.writeBytes(bytes)
                        val descriptor = android.os.ParcelFileDescriptor.open(file, android.os.ParcelFileDescriptor.MODE_READ_ONLY)
                        val output = android.graphics.pdf.PdfRenderer(descriptor).use { renderer ->
                            renderer.openPage(0).use { page ->
                                val scale = minOf(1200f / page.width, 1600f / page.height)
                                val bitmap = Bitmap.createBitmap(maxOf(1, (page.width * scale).toInt()), maxOf(1, (page.height * scale).toInt()), Bitmap.Config.ARGB_8888)
                                bitmap.eraseColor(android.graphics.Color.WHITE)
                                page.render(bitmap, null, null, android.graphics.pdf.PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                ByteArrayOutputStream().use { stream ->
                                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                    bitmap.recycle()
                                    stream.toByteArray()
                                }
                            }
                        }
                        activity.runOnUiThread { result.success(output) }
                    } catch (_: Exception) { activity.runOnUiThread { result.error("FILE_INVALID", null, null) } }
                    finally { file.delete() }
                }.start()
            }
            "pick" -> {
                if (pending != null) { result.error("BUSY", null, null); return }
                pending = result
                try {
                    activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        type = "*/*"
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/jpeg", "image/png", "application/pdf"))
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }, 2401)
                } catch (_: Exception) { pending = null; result.error("FILE_UNAVAILABLE", null, null) }
            }
            else -> result.notImplemented()
        }
    }
    fun selected(request: Int, code: Int, data: Intent?): Boolean {
        if (request != 2401) return false
        val result = pending ?: return true
        pending = null
        if (code != Activity.RESULT_OK || data?.data == null) { result.success(null); return true }
        // Decode away from the UI thread. Raw selected bytes are memory-only.
        Thread {
            try {
                val bytes = activity.contentResolver.openInputStream(data.data!!)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        if (output.size() + read > 5 * 1024 * 1024) throw IllegalArgumentException()
                        output.write(buffer, 0, read)
                    }
                    output.toByteArray()
                } ?: throw IllegalArgumentException()
                val pdf = bytes.take(5).toByteArray().contentEquals("%PDF-".toByteArray())
                val output = if (pdf) bytes else {
                    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                    if (bounds.outMimeType !in listOf("image/jpeg", "image/png") || bounds.outWidth <= 0 ||
                        bounds.outHeight <= 0 || bounds.outWidth.toLong() * bounds.outHeight > 20_000_000) throw IllegalArgumentException()
                    val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: throw IllegalArgumentException()
                    val orientation = if (bounds.outMimeType == "image/jpeg") ExifInterface(ByteArrayInputStream(bytes)).getAttributeInt(ExifInterface.TAG_ORIENTATION, 1) else 1
                    val matrix = Matrix()
                    when (orientation) {
                        2 -> matrix.setScale(-1f, 1f)
                        3 -> matrix.setRotate(180f)
                        4 -> matrix.setScale(1f, -1f)
                        5 -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
                        6 -> matrix.setRotate(90f)
                        7 -> { matrix.setRotate(270f); matrix.postScale(-1f, 1f) }
                        8 -> matrix.setRotate(270f)
                    }
                    val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
                    ByteArrayOutputStream().use { stream ->
                        rotated.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                        val encoded = stream.toByteArray()
                        if (rotated !== bitmap) rotated.recycle()
                        bitmap.recycle()
                        encoded
                    }
                }
                if (output.size > 5 * 1024 * 1024) throw IllegalArgumentException()
                activity.runOnUiThread { result.success(mapOf("bytes" to output, "pdf" to pdf)) }
            } catch (_: Exception) { activity.runOnUiThread { result.error("FILE_INVALID", null, null) } }
        }.start()
        return true
    }
    fun dispose() { pending?.success(null); pending = null }
}
