// T-101 generated transport smoke only; real artifact/security evidence is native API.
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

const exportId = '11111111-1111-4111-8111-111111111111';

class ExportAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  final csv = utf8
      .encode('\ufeff"section","value"\r\n"SUMMARY","9007199254740993"\r\n');
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    if (o.path.endsWith('/download')) {
      return ResponseBody.fromBytes(csv, 200, headers: {
        Headers.contentTypeHeader: ['text/csv; charset=utf-8']
      });
    }
    final body = o.method == 'POST'
        ? {'exportId': exportId}
        : {
            'exportId': exportId,
            'status': 'READY',
            'format': 'CSV',
            'from': '2026-11-19',
            'to': '2026-11-19',
            'createdAt': '2026-11-19T01:00:00Z',
            'expiresAt': '2026-11-20T01:00:00Z',
            'sizeBytes': csv.length,
            'sha256': 'a' * 64,
            'downloadPath': '/api/v1/vendor/reports/exports/$exportId/download'
          };
    return ResponseBody.fromString(
        jsonEncode(body), o.method == 'POST' ? 201 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

void main() {
  test(
      'T-101 generated export client freezes exact date/CSV/key and downloads UTF-8 bytes without JSON/number conversion',
      () async {
    final f = ExportAdapter(),
        dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = f;
    addTearDown(() => dio.close(force: true));
    final api = VendorReportExportsApi(dio);
    final created = (await api.reportExportsControllerCreate(
            idempotencyKey: 'synthetic-export-key',
            reportExportInput: ReportExportInput(
                from: '2026-11-19',
                to: '2026-11-19',
                format: ReportExportInputFormatEnum.CSV)))
        .data!;
    expect(created.exportId, exportId);
    expect(f.calls.last.headers['Idempotency-Key'], 'synthetic-export-key');
    expect(jsonDecode(f.calls.last.data as String),
        {'from': '2026-11-19', 'to': '2026-11-19', 'format': 'CSV'});
    final status =
        (await api.reportExportsControllerStatus(id: exportId)).data!;
    expect(status.status.value, 'READY');
    expect(status.from, DateTime(2026, 11, 19));
    expect(status.downloadPath,
        '/api/v1/vendor/reports/exports/$exportId/download');
    final file =
        (await api.reportExportsControllerDownload(id: exportId)).data!;
    expect(file, f.csv);
    expect(utf8.decode(file), contains('9007199254740993'));
    expect(f.calls.last.responseType, ResponseType.bytes);
    expect(
        f.calls.last.path, '/api/v1/vendor/reports/exports/$exportId/download');
  });
}
