# supplybiz_api_client.model.ReportSummary

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
**totalSalesPaise** | **String** | Gross delivered-order totals plus POS totals on actual completion/sale dates. Includes charges; not receipts. |
**totalOrders** | **int** | Retained orders scheduled in range; POS is not an order. |
**deliveredOrders** | **int** | Scheduled-in-range orders now DELIVERED. |
**cancelledOrders** | **int** | Scheduled-in-range orders now CANCELLED; excludes REJECTED/FAILED. |
**milkSoldLitres** | **String** | Known milk litres from immutable delivered/POS line snapshots in actual completion/sale range. |
**milkSoldUnmeasuredLines** | **int** | Legacy zero-volume/unknown-classification or non-volume milk lines. Milk total is incomplete when nonzero; never infer history from current catalog. |
**totalEarningsPaise** | **String** | Net external receipts by ledger value date: payment/POS/confirmed-claim credit roots and reversal chains, plus paid walk-ins once. Opening credits excluded. May be negative for corrections. |
**pendingPaymentsPaise** | **String** | Current positive Khata due summed per customer, including archived/inactive links, as of serverTime; independent of date range. |
**activeCustomers** | **int** | Current ACTIVE non-deleted customer links; independent of range. |
**productSalesPaise** | **String** | Range item sales excluding delivery charges; matches complete product table total. |
**deliveryChargesPaise** | **String** |  |
**discountPaise** | **String** | Stored order discounts; zero under current scope. |
**unitemizedSalesPaise** | **String** | Legacy missing/inconsistent item subtotal gap. Sales = products + charges - discounts + this gap. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


