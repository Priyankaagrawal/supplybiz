# supplybiz_api_client.model.CustomerInput

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  |
**mobile** | **String** | Indian mobile, ten digits or +91-prefixed. Stored in +91 form. |
**email** | **String** |  | [optional]
**address** | **String** | Defaults to empty on creation; omission preserves the address on PATCH. | [optional]
**preferredPayment** | **String** | Defaults to CASH on creation; omission preserves the method on PATCH. | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


