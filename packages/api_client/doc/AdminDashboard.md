# supplybiz_api_client.model.AdminDashboard

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**serverTime** | [**DateTime**](DateTime.md) |  |
**vendorsTotal** | **int** |  |
**vendorsSuspended** | **int** |  |
**kycPending** | **int** |  |
**kycVerified** | **int** |  |
**customersTotal** | **int** |  |
**customersBlocked** | **int** |  |
**ordersTotal** | **int** |  |
**ordersDelivered** | **int** |  |
**ordersFailed** | **int** |  |
**recordedGmvPaise** | **String** | Delivered-order component of PRD GMV only; quick-sale value unavailable until T-079/T-080. All-time stored DELIVERED order totals, including delivery charges and discounts; not cash receipts. Decimal integer paise string preserves BigInt precision. |
**gmvScope** | **String** | Full platform GMV also requires quick-sale value, unavailable before T-079/T-080. |
**planAssignmentsTotal** | **int** | All historical audited assignment rows, including superseded grants; never revenue. |
**planRevenueStatus** | **String** | Automated plan billing is deferred; no inferred revenue. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


