# supplybiz_api_client.model.AvailabilityPatch

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**version** | **int** |  |
**acceptingToday** | **bool** | False rejects new one-time orders for today; existing orders remain. | [optional]
**deliveryPaused** | **bool** | Open-ended delivery pause. True cancels NEW/ACCEPTED/PREPARING orders today onward; progressed orders remain. | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


