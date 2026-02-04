import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required ApiInfo info,
    required List<T> results,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
}

@freezed
class ApiInfo with _$ApiInfo {
  const factory ApiInfo({
    required int count,
    required int pages,
    String? next,
    String? prev,
  }) = _ApiInfo;

  factory ApiInfo.fromJson(Map<String, dynamic> json) =>
      _$ApiInfoFromJson(json);
}
