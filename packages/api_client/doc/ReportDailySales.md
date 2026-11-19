# supplybiz_api_client.model.ReportDailySales

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**from** | [**DateTime**](DateTime.md) |  |
**to** | [**DateTime**](DateTime.md) |  |
**serverTime** | [**DateTime**](DateTime.md) |  |
**businessDate** | [**DateTime**](DateTime.md) |  |
**bucket** | **String** | DAY through 62 inclusive days; otherwise Monday-based weeks clipped to requested range. Zero periods included. |
**items** | [**List&lt;ReportSalesBucket&gt;**](ReportSalesBucket.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


