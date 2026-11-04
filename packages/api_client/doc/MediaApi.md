# supplybiz_api_client.api.MediaApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminMediaControllerContent**](MediaApi.md#adminmediacontrollercontent) | **GET** /api/v1/admin/media/{id}/content |
[**mediaControllerContent**](MediaApi.md#mediacontrollercontent) | **GET** /api/v1/media/{id}/content |
[**mediaControllerUpload**](MediaApi.md#mediacontrollerupload) | **POST** /api/v1/media |


# **adminMediaControllerContent**
> Uint8List adminMediaControllerContent(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getMediaApi();
final String id = id_example; // String |

try {
    final response = api.adminMediaControllerContent(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MediaApi->adminMediaControllerContent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaControllerContent**
> Uint8List mediaControllerContent(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getMediaApi();
final String id = id_example; // String |

try {
    final response = api.mediaControllerContent(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MediaApi->mediaControllerContent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mediaControllerUpload**
> MediaResponse mediaControllerUpload(idempotencyKey, file, purpose)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getMediaApi();
final String idempotencyKey = idempotencyKey_example; // String |
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile |
final String purpose = purpose_example; // String |

try {
    final response = api.mediaControllerUpload(idempotencyKey, file, purpose);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MediaApi->mediaControllerUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **file** | **MultipartFile**|  |
 **purpose** | **String**|  |

### Return type

[**MediaResponse**](MediaResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

