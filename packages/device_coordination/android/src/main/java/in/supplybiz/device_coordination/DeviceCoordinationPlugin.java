package in.supplybiz.device_coordination;

import android.os.Handler;
import android.os.Looper;
import android.content.Context;
import android.content.pm.PackageManager;
import java.util.ArrayDeque;
import java.util.UUID;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/** All callbacks run on Android's main thread. WorkManager uses the app process. */
public final class DeviceCoordinationPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private static final Handler handler = new Handler(Looper.getMainLooper());
    private static final ArrayDeque<Waiter> waiting = new ArrayDeque<>();
    private static Waiter held;
    private MethodChannel channel;
    private Context context;

    private static final class Waiter {
        final DeviceCoordinationPlugin engine;
        final MethodChannel.Result result;
        final String token = UUID.randomUUID().toString();
        Runnable timeout;
        Waiter(DeviceCoordinationPlugin engine, MethodChannel.Result result) {
            this.engine = engine;
            this.result = result;
        }
    }

    @Override public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "in.supplybiz/device-coordination");
        channel.setMethodCallHandler(this);
    }

    @Override public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.equals("version")) {
            try {
                result.success(context.getPackageManager().getPackageInfo(context.getPackageName(), 0).versionName);
            } catch (PackageManager.NameNotFoundException e) {
                result.error("VERSION_UNAVAILABLE", "App version unavailable.", null);
            }
        } else if (call.method.equals("acquire")) {
            Waiter next = new Waiter(this, result);
            next.timeout = () -> {
                if (waiting.remove(next)) result.error("COORDINATION_BUSY", "Retry the operation.", null);
            };
            waiting.add(next);
            handler.postDelayed(next.timeout, 120000);
            grant();
        } else if (call.method.equals("release")) {
            String token = call.argument("token");
            if (held == null || held.engine != this || !held.token.equals(token)) {
                result.error("INVALID_LEASE", "Invalid device coordination lease.", null);
                return;
            }
            held = null;
            result.success(null);
            grant();
        } else {
            result.notImplemented();
        }
    }

    private static void grant() {
        if (held != null || waiting.isEmpty()) return;
        held = waiting.removeFirst();
        handler.removeCallbacks(held.timeout);
        held.result.success(held.token);
    }

    @Override public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        // A stopped worker/engine cannot strand a lease or its queued callbacks.
        waiting.removeIf(item -> {
            if (item.engine != this) return false;
            handler.removeCallbacks(item.timeout);
            return true;
        });
        if (held != null && held.engine == this) held = null;
        grant();
        channel = null;
        context = null;
    }
}
