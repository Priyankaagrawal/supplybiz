package `in`.supplybiz.supplybiz_mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.math.BigDecimal
import java.math.BigInteger

// T-083. No provider response/status/transaction reference is read or logged.
internal class UpiPayments(private val activity: FlutterActivity) {
    private var pending: MethodChannel.Result? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "pay") { result.notImplemented(); return }
        if (pending != null) { result.error("BUSY", "Payment review pending", null); return }
        val uri = call.argument<String>("uri")?.let(::validated)
        if (uri == null) { result.error("INVALID_UPI", "Invalid payment details", null); return }
        pending = result
        try {
            // Starting directly needs neither installed-app enumeration nor broad queries.
            activity.startActivityForResult(Intent(Intent.ACTION_VIEW, uri)
                .addCategory(Intent.CATEGORY_BROWSABLE), REQUEST)
        } catch (_: ActivityNotFoundException) { finish(false) }
          catch (_: SecurityException) { finish(false) }
    }

    fun returned(requestCode: Int): Boolean {
        if (requestCode != REQUEST) return false
        finish(true) // Only means an activity returned, including cancellation.
        return true
    }
    fun dispose() { finish(false) }
    private fun finish(returned: Boolean) {
        val result = pending
        pending = null
        result?.success(returned)
    }
    companion object {
        const val REQUEST = 7103
        fun validated(raw: String): Uri? = try {
            val uri = Uri.parse(raw)
            val keys = setOf("pa", "pn", "am", "cu", "tn")
            val fields = uri.queryParameterNames
            val amount = uri.getQueryParameter("am") ?: ""
            if (raw.length > 2500 || uri.scheme != "upi" || uri.authority != "pay" ||
                !uri.path.isNullOrEmpty() || uri.fragment != null || fields != keys ||
                keys.any { uri.getQueryParameters(it).size != 1 } ||
                !Regex("^[\\w.-]{2,256}@[a-zA-Z]{2,64}$").matches(uri.getQueryParameter("pa") ?: "") ||
                (uri.getQueryParameter("pn")?.length ?: 0) !in 1..200 ||
                uri.getQueryParameter("cu") != "INR" ||
                uri.getQueryParameter("tn") != "Supply Biz Khata" ||
                !Regex("^(0|[1-9][0-9]{0,16})\\.[0-9]{2}$").matches(amount)) null
            else {
                val paise = BigDecimal(amount).movePointRight(2).toBigIntegerExact()
                if (paise <= BigInteger.ZERO || paise > BigInteger("9223372036854775807")) null else uri
            }
        } catch (_: Exception) { null }
    }
}
