import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import 'api.dart';

class Uploads {
  final Api api;
  Uploads(this.api);
  Future<String?> pick(String purpose, {String? resourceId}) async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: purpose == 'HEALTH_DOCUMENT'
          ? ['jpg', 'jpeg', 'png', 'webp', 'pdf']
          : ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null) return null;
    final file = result;
    final length = await file.length();
    if (length == null || length <= 0 || length > 10 * 1024 * 1024) {
      throw const ApiFailure('10MB 이하의 파일을 선택해주세요.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const ApiFailure('10MB 이하의 파일을 선택해주세요.');
    }
    final type = switch (file.extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => throw const ApiFailure('지원하지 않는 파일 형식입니다.'),
    };
    final upload = object(
      await api.call(
        '/uploads',
        method: 'POST',
        data: {
          'purpose': purpose,
          'filename': file.name,
          'contentType': type,
          'size': bytes.length,
          'resourceId': ?resourceId,
        },
      ),
    );
    // Never rewrite a signed URL: configure the server S3_PUBLIC_ENDPOINT for devices.
    final transport = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );
    try {
      await transport.put<dynamic>(
        label(upload['uploadUrl']),
        data: Stream.value(bytes),
        options: Options(
          headers: {
            ...object(upload['headers']),
            'Content-Length': bytes.length,
          },
          contentType: type,
        ),
      );
    } on DioException {
      throw const ApiFailure('파일 전송을 완료하지 못했어요. 다시 선택해주세요.');
    } finally {
      transport.close();
    }
    final id = label(upload['id']);
    await api.call('/uploads/$id/complete', method: 'POST');
    for (var attempt = 0; attempt < 30; attempt++) {
      final result = object(await api.call('/uploads/$id'));
      if (result['status'] == 'READY') return id;
      if (result['status'] == 'REJECTED' || result['status'] == 'DELETED') {
        throw ApiFailure(
          label(result['rejectionReason']).isEmpty
              ? '파일 검사에 실패했어요. 다른 파일을 선택해주세요.'
              : label(result['rejectionReason']),
        );
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw const ApiFailure('파일 검사 대기 시간이 길어지고 있어요. 서버 워커 상태를 확인하고 다시 시도해주세요.');
  }
}
