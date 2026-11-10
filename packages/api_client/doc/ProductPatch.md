# supplybiz_api_client.model.ProductPatch

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  | [optional]
**productType** | **String** | One of the vendor category productTypes (admin-managed). | [optional]
**milkType** | **String** |  | [optional]
**unitValue** | **num** |  | [optional]
**unitType** | **String** |  | [optional]
**sellingPricePaise** | **int** |  | [optional]
**subscriptionPricePaise** | **int** |  | [optional]
**stockQty** | **int** |  | [optional] [default to 0]
**moq** | **int** |  | [optional] [default to 1]
**description** | **String** |  | [optional] [default to '']
**imageMediaId** | **String** |  | [optional]
**isActive** | **bool** |  | [optional] [default to true]
**stockReason** | **String** | Required when changing stockQty. | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


