# supplybiz_api_client.model.CompleteSaleInput

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**vendorCustomerId** | **String** | Omitted for anonymous walk-in; no synthetic customer is created. | [optional]
**items** | [**List&lt;SaleLineInput&gt;**](SaleLineInput.md) |  |
**paidPaise** | **String** | Recorded external payment, 0 through server total. Walk-in must equal total. |
**paymentMethod** | **String** |  |
**clientCreatedAt** | [**DateTime**](DateTime.md) | Untrusted offline audit metadata only; never controls business date, authorization or posting. | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


