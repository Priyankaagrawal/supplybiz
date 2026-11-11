package `in`.supplybiz.supplybiz_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Base64
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val deviceLocation by lazy { DeviceLocation(this) }
    private val onboardingFiles by lazy { OnboardingFiles(this) }
    private var receiver: BroadcastReceiver? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "in.supplybiz/customers").setMethodCallHandler { call, result ->
            if (call.method != "dial") { result.notImplemented(); return@setMethodCallHandler }
            val mobile = call.argument<String>("mobile") ?: ""
            if (!Regex("^\\+91[6-9][0-9]{9}$").matches(mobile)) { result.success(false); return@setMethodCallHandler }
            try {
                startActivity(Intent(Intent.ACTION_DIAL, Uri.fromParts("tel", mobile, null)))
                result.success(true)
            } catch (_: Exception) { result.success(false) }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "in.supplybiz/location").setMethodCallHandler { call, result ->
            when (call.method) {
                "current" -> deviceLocation.current(result)
                "cancel" -> { deviceLocation.dispose(); result.success(null) }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "in.supplybiz/app").setMethodCallHandler { call, result ->
            when (call.method) {
                "version" -> {
                    @Suppress("DEPRECATION")
                    val info = packageManager.getPackageInfo(packageName, 0)
                    result.success(info.versionName)
                }
                "openStore" -> {
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")))
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$packageName")))
                            result.success(true)
                        } catch (_: Exception) { result.success(false) }
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "in.supplybiz/onboarding").setMethodCallHandler(onboardingFiles::handle)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "in.supplybiz/sms")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "stop" -> { stopRetriever(); result.success(null) }
                "start" -> {
                    stopRetriever()
                    val listener = object : BroadcastReceiver() {
                        override fun onReceive(context: Context, intent: Intent) {
                            if (intent.action != SmsRetriever.SMS_RETRIEVED_ACTION) return
                            val status = if (Build.VERSION.SDK_INT >= 33)
                                intent.getParcelableExtra(SmsRetriever.EXTRA_STATUS, Status::class.java)
                            else @Suppress("DEPRECATION") intent.getParcelableExtra<Status>(SmsRetriever.EXTRA_STATUS)
                            if (status?.statusCode == CommonStatusCodes.SUCCESS) {
                                val message = intent.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE) ?: ""
                                val code = Regex("(?<![0-9])[0-9]{6}(?![0-9])").find(message)?.value
                                if (code != null) channel?.invokeMethod("code", code)
                            }
                            stopRetriever()
                        }
                    }
                    receiver = listener
                    val filter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
                    if (Build.VERSION.SDK_INT >= 33)
                        registerReceiver(listener, filter, SmsRetriever.SEND_PERMISSION, null, Context.RECEIVER_EXPORTED)
                    else registerReceiver(listener, filter, SmsRetriever.SEND_PERMISSION, null)
                    SmsRetriever.getClient(this).startSmsRetriever()
                        .addOnSuccessListener { result.success(appHash()) }
                        .addOnFailureListener { stopRetriever(); result.success(null) }
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun appHash(): String? = try {
        val signatures = if (Build.VERSION.SDK_INT >= 28) {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES).signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
        }
        signatures?.firstOrNull()?.let {
            val input = "$packageName ${it.toCharsString()}".toByteArray(Charsets.UTF_8)
            Base64.encodeToString(MessageDigest.getInstance("SHA-256").digest(input).copyOfRange(0, 9), Base64.NO_PADDING or Base64.NO_WRAP).take(11)
        }
    } catch (_: Exception) { null }

    private fun stopRetriever() {
        receiver?.let { unregisterReceiver(it) }
        receiver = null
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!onboardingFiles.selected(requestCode, resultCode, data)) super.onActivityResult(requestCode, resultCode, data)
    }
    override fun onDestroy() {
        deviceLocation.dispose()
        onboardingFiles.dispose()
        stopRetriever()
        channel?.setMethodCallHandler(null)
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == DeviceLocation.PERMISSION) deviceLocation.permissionResult()
    }
}
