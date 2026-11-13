# supplybiz_api_client.model.OrderTransitionInput

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**to** | **String** |  |
**version** | **int** |  |
**reason** | **String** | REJECTED: CUSTOMER_UNAVAILABLE/OUT_OF_STOCK/NOT_SERVICEABLE/CUSTOMER_REQUEST/OTHER. FAILED: required nonempty free text, up to 200 characters. | [optional]
**reasonText** | **String** | Required for OTHER; 5–200 characters. | [optional]
**payment** | [**DeliveryPaymentInput**](DeliveryPaymentInput.md) | Required for DELIVERED; collected=false forbids method/amount. | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


