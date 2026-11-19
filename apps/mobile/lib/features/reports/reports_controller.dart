// T-102 / S-V-17. Server-authorized reports; exact values and frozen CSV retries.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/app_config.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../auth/session_controller.dart';
import '../onboarding/onboarding_controller.dart';
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionParseDate, subscriptionDate;

final reportsProvider =
    ChangeNotifierProvider.autoDispose<ReportsController>((ref) {
  final identity = ref.watch(sessionProvider
          .select((s) => (s.user?.id, s.user?.activeRole?.value))),
      config = ref.read(authConfigProvider);
  final client = NetworkClient(
      baseUrl: Uri.parse(config.baseUrl).replace(path: '').toString(),
      session: ref.read(sessionProvider.notifier),
      adapter: ref.read(authAdapterProvider),
      appVersion: () => ref.read(configProvider).version);
  ref.onDispose(client.close);
  return ReportsController(client, ref.read(onboardingDraftsProvider),
      '${config.baseUrl}:${identity.$1}:${identity.$2}:reports');
});

bool validReportRange(String from, String to) {
  final a = subscriptionParseDate(from), b = subscriptionParseDate(to);
  if (a == null || b == null || a.year < 1 || b.year < 1) return false;
  final days = DateTime.utc(b.year, b.month, b.day)
      .difference(DateTime.utc(a.year, a.month, a.day))
      .inDays;
  return days >= 0 && days < 366;
}

typedef ShareReport = Future<bool> Function(
    ReportExportStatus status, Uint8List bytes);
Future<bool> shareReport(ReportExportStatus status, Uint8List bytes) async =>
    await const MethodChannel('in.supplybiz/reports')
        .invokeMethod<bool>('share', {
      'id': status.exportId,
      'from': subscriptionDate(status.from),
      'to': subscriptionDate(status.to),
      'sha256': status.sha256,
      'size': status.sizeBytes,
      'bytes': bytes,
    }) ??
    false;

class ReportsController extends ChangeNotifier {
  ReportsController(NetworkClient client, this.store, this.owner,
      {this.share = shareReport})
      : api = VendorReportsApi(client.dio),
        exports = VendorReportExportsApi(client.dio);
  final VendorReportsApi api;
  final VendorReportExportsApi exports;
  final OnboardingDrafts store;
  final String owner;
  final ShareReport share;
  ReportSummary? summary;
  ReportDailySales? daily;
  ReportProducts? products;
  AppFailure? failure, detailFailure, exportFailure;
  bool busy = false,
      exporting = false,
      stale = true,
      locked = false,
      cacheUnavailable = false,
      chooserOpened = false,
      exportExpired = false;
  int offset = 0;
  bool _disposed = false, _restored = false, _storageReady = false;
  Map<String, String> _saved = {};
  String? get pendingFrom => _saved['exportFrom'];
  String? get pendingTo => _saved['exportTo'];
  bool get hasPending => _saved['key'] != null;
  bool get canResetExport => _saved['exportId'] != null || exportExpired;
  String? get from => summary == null ? null : subscriptionDate(summary!.from);
  String? get to => summary == null ? null : subscriptionDate(summary!.to);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  AppFailure _error(Object e) => e is DioException
      ? mapDioFailure(e)
      : e is AppFailure
          ? e
          : const UnknownFailure();
  bool _denied(AppFailure e) =>
      e is UnauthorizedFailure || e is ForbiddenFailure || e is NotFoundFailure;
  bool _plan(AppFailure e) =>
      e is ForbiddenFailure && e.code == 'PLAN_FEATURE_LOCKED';
  Future<void> _save() async {
    if (!_storageReady) throw StateError('Report storage unavailable');
    if (!_disposed) await store.write(owner, Map.of(_saved));
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      _saved = await store.read(owner);
      if (_disposed) return;
      _storageReady = true;
      if (_saved['summary'] != null) {
        summary = ReportSummary.fromJson(
            Map<String, dynamic>.from(jsonDecode(_saved['summary']!) as Map));
      }
    } catch (_) {
      cacheUnavailable = true;
      summary = null;
      _restored = false;
      _storageReady = false;
    }
  }

  Future<void> _clearPrivate() async {
    summary = null;
    daily = null;
    products = null;
    stale = true;
    _saved = {};
    try {
      await _save();
    } catch (_) {
      cacheUnavailable = true;
    }
  }

  Future<void> load({String? from, String? to, bool today = false}) async {
    if (_disposed || busy || exporting) return;
    if ((from != null || to != null) &&
        !validReportRange(from ?? '', to ?? '')) {
      return;
    }
    busy = true;
    failure = null;
    detailFailure = null;
    locked = false;
    stale = true;
    daily = null;
    products = null;
    offset = 0;
    _notify();
    try {
      await _restore();
      if (_disposed) return;
      final a = today ? null : from ?? this.from,
          b = today ? null : to ?? this.to;
      // Never label a previous range with new dates during a failed request.
      if (from != null && (from != this.from || to != this.to)) summary = null;
      try {
        final result =
            (await api.reportsControllerSummary(from: a, to: b)).data!;
        if (_disposed) return;
        summary = result;
        stale = false;
        _saved['summary'] = jsonEncode(result.toJson());
        try {
          await _save();
        } catch (_) {
          cacheUnavailable = true;
        }
      } catch (e) {
        if (_disposed) return;
        failure = _error(e);
        if (_denied(failure!)) await _clearPrivate();
        return;
      }
      if (_disposed) return;
      await _details();
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _details() async {
    try {
      final result =
          (await api.reportsControllerDaily(from: from, to: to)).data!;
      if (_disposed) return;
      daily = result;
      final rows = (await api.reportsControllerProducts(
              from: from, to: to, limit: 20, offset: offset))
          .data!;
      if (_disposed) return;
      products = rows;
    } catch (e) {
      if (_disposed) return;
      detailFailure = _error(e);
      if (_plan(detailFailure!)) {
        locked = true;
        daily = null;
        products = null;
      } else if (_denied(detailFailure!)) {
        await _clearPrivate();
      }
    }
  }

  Future<void> page(int next) async {
    if (_disposed || busy || exporting || stale || next < 0) return;
    busy = true;
    detailFailure = null;
    _notify();
    try {
      final result = (await api.reportsControllerProducts(
              from: from, to: to, limit: 20, offset: next))
          .data!;
      if (_disposed) return;
      products = result;
      offset = next;
    } catch (e) {
      if (_disposed) return;
      detailFailure = _error(e);
      if (_plan(detailFailure!)) {
        locked = true;
        daily = null;
        products = null;
      } else if (_denied(detailFailure!)) {
        await _clearPrivate();
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> resetExport() async {
    if (exporting || busy || !canResetExport) return;
    final previous = Map<String, String>.of(_saved);
    for (final k in ['key', 'exportFrom', 'exportTo', 'exportId']) {
      _saved.remove(k);
    }
    try {
      await _save();
      chooserOpened = false;
      exportExpired = false;
      exportFailure = null;
    } catch (_) {
      _saved = previous;
      cacheUnavailable = true;
    }
    _notify();
  }

  Future<void> exportCsv() async {
    if (_disposed ||
        busy ||
        exporting ||
        stale ||
        locked ||
        summary == null ||
        exportExpired) {
      return;
    }
    exporting = true;
    exportFailure = null;
    chooserOpened = false;
    _notify();
    try {
      if (!hasPending) {
        _saved.addAll(
            {'key': const Uuid().v4(), 'exportFrom': from!, 'exportTo': to!});
      }
      // Must durably freeze key/body BEFORE sending, including after a failed local save.
      await _save();
      if (_disposed) return;
      var id = _saved['exportId'];
      if (id == null) {
        final created = (await exports.reportExportsControllerCreate(
                idempotencyKey: _saved['key']!,
                reportExportInput: ReportExportInput(
                    from: pendingFrom!,
                    to: pendingTo!,
                    format: ReportExportInputFormatEnum.CSV)))
            .data!;
        if (_disposed) return;
        id = created.exportId;
        _saved['exportId'] = id;
        await _save();
        if (_disposed) return;
      }
      final status =
          (await exports.reportExportsControllerStatus(id: id)).data!;
      if (_disposed) return;
      if (status.status.value != 'READY') {
        exportExpired = true;
        return;
      }
      if (status.exportId != id ||
          subscriptionDate(status.from) != pendingFrom ||
          subscriptionDate(status.to) != pendingTo ||
          status.format.value != 'CSV') {
        throw const UnknownFailure();
      }
      // Ignore downloadPath and remote filenames; only the generated authenticated UUID route.
      final bytes =
          (await exports.reportExportsControllerDownload(id: id)).data!;
      if (_disposed) return;
      if (bytes.length != status.sizeBytes ||
          bytes.isEmpty ||
          bytes.length > 8388608) {
        throw const UnknownFailure();
      }
      chooserOpened = await share(status, bytes);
      if (!chooserOpened && !_disposed) exportFailure = const UnknownFailure();
    } catch (e) {
      if (_disposed) return;
      exportFailure = _error(e);
      if (e is DioException && [410, 413].contains(e.response?.statusCode)) {
        exportExpired = true;
      }
      if (exportFailure is NotFoundFailure && _saved['exportId'] != null) {
        exportExpired = true;
      }
      if (_plan(exportFailure!)) {
        locked = true;
        daily = null;
        products = null;
      } else if (_denied(exportFailure!) && !exportExpired) {
        await _clearPrivate();
      }
    } finally {
      exporting = false;
      _notify();
    }
  }
}
