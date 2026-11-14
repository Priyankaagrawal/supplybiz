# supplybiz_api_client.model.RecordPaymentInput

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**vendorCustomerId** | **String** |  |
**amountPaise** | **String** | Positive exact integer paise as decimal string, signed BIGINT maximum. |
**method** | **String** | External payment record only; no platform money movement. |
**receivedOn** | [**DateTime**](DateTime.md) | Received business date, YYYY-MM-DD. |
**note** | **String** |  | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


