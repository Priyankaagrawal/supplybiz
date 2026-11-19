# supplybiz_api_client.model.ReportExportStatus

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**exportId** | **String** |  |
**status** | **String** | Generated synchronously within operational limits. Download always rechecks live access. |
**from** | [**DateTime**](DateTime.md) |  |
**to** | [**DateTime**](DateTime.md) |  |
**createdAt** | [**DateTime**](DateTime.md) |  |
**expiresAt** | [**DateTime**](DateTime.md) |  |
**format** | **String** |  |
**sizeBytes** | **int** |  |
**sha256** | **String** |  |
**downloadPath** | **String** | Same-API authenticated route only, never a filesystem path/public URL. Null after 24-hour artifact/retry window. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


