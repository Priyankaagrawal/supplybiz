# supplybiz_api_client.model.AvailabilityResponse

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**version** | **int** |  |
**acceptingToday** | **bool** |  |
**deliveryPaused** | **bool** |  |
**deliveryPausedUntil** | [**DateTime**](DateTime.md) | Legacy finite pause end; PATCH deliveryPaused always clears it to implement open-ended pause/resume. |
**canResume** | **bool** |  |
**canReduceActivity** | **bool** |  |
**serverTime** | **String** |  |
**businessDate** | [**DateTime**](DateTime.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


