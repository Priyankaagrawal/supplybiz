# supplybiz_api_client.model.VendorDashboard

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**serverTime** | [**DateTime**](DateTime.md) | Database snapshot time for last-updated display. |
**businessDate** | [**DateTime**](DateTime.md) |  |
**date** | [**DateTime**](DateTime.md) | Selected IST date. Order counts use scheduled delivery date; sales use actual completion/sale date. |
**shopName** | **String** |  |
**city** | **String** |  |
**shopPhotoMediaId** | **String** | Owned photo ID for the existing authorized media route. |
**verified** | **bool** | Stored VERIFIED KYC only; no provider verification implied. |
**todayOrders** | **int** | All retained orders scheduled for selected date, including cancelled/rejected/failed. |
**pendingOrders** | **int** | NEW, ACCEPTED, PREPARING or OUT_FOR_DELIVERY on selected delivery date. |
**completedOrders** | **int** | DELIVERED on selected delivery date. |
**todaySalesPaise** | **String** | Selected IST completion/sale date gross: delivered order totals plus POS totals. Stored discounts/delivery charges included; not receipts, ledger credits or plan revenue. |
**totalEarningsPaise** | **String** | Lifetime DELIVERED order totals plus POS totals. Recorded sales, not profit or money received; independent payments/claims/reversals are not new sales. |
**milkStockLitres** | **String** | Current known milk litres: active non-deleted MILK stock times pack volume, L plus ML/1000. Exact decimal, independent of date. |
**milkStockUnmeasuredProducts** | **int** | Active stocked milk products in G/KG/PCS excluded from litres because volume is unknown. Disclose incomplete volume when nonzero. |
**activeCustomers** | **int** | Current ACTIVE non-deleted vendor customer links including offline customers; independent of date. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


