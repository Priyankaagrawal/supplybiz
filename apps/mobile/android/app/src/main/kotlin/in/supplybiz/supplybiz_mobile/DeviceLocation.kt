package `in`.supplybiz.supplybiz_mobile

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/** Foreground, user-initiated fix only. Never returns stale last-known locations. */
class DeviceLocation(private val activity: Activity) : LocationListener {
    companion object { const val PERMISSION = 25025 }
    private val manager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val handler = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null
    private val timeout = Runnable { fail("LOCATION_UNAVAILABLE") }
    private fun allowed() = activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
        activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    fun current(result: MethodChannel.Result) {
        if (pending != null) { result.error("LOCATION_BUSY", null, null); return }
        pending = result
        if (!allowed()) activity.requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), PERMISSION)
        else locate()
    }
    fun permissionResult() {
        if (pending == null) return
        if (allowed()) locate() else fail("LOCATION_DENIED")
    }
    private fun locate() {
        try {
            val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER).filter { manager.isProviderEnabled(it) }
            if (providers.isEmpty()) { fail("LOCATION_UNAVAILABLE"); return }
            handler.postDelayed(timeout, 20000)
            providers.forEach { manager.requestLocationUpdates(it, 0L, 0f, this, Looper.getMainLooper()) }
        } catch (_: Exception) { fail("LOCATION_UNAVAILABLE") }
    }
    override fun onLocationChanged(location: Location) {
        val result = pending ?: return
        cleanup()
        result.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
    }
    @Deprecated("Legacy location callback")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}
    private fun cleanup() {
        pending = null
        handler.removeCallbacks(timeout)
        try { manager.removeUpdates(this) } catch (_: Exception) {}
    }
    private fun fail(code: String) { val result = pending; cleanup(); result?.error(code, null, null) }
    fun dispose() { fail("LOCATION_CANCELLED") }
}
