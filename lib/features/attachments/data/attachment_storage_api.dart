import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import 'attachment_storage.dart';

const int multipartThresholdBytes = 100 * 1024 * 1024; // 100 MB
const int multipartChunkSizeBytes = 20 * 1024 * 1024; // 20 MB

class AttachmentStorageApi {
  AttachmentStorageApi(this._supabase, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SupabaseClient _supabase;
  final http.Client _http;

  Future<String> upload(Attachment attachment, String absolutePath) async {
    final file = File(absolutePath);
    if (attachment.byteSize > multipartThresholdBytes) {
      return _uploadMultipart(attachment, file);
    }
    return _uploadSinglePart(attachment, file.openRead());
  }

  Future<String> uploadBytes(Attachment attachment, Uint8List bytes) async {
    return _uploadSinglePart(attachment, Stream.value(bytes));
  }

  Future<String> _uploadSinglePart(
    Attachment attachment,
    Stream<List<int>> bytes,
  ) async {
    final body = _attachmentBody(attachment);
    final prepared = await _invoke({...body, 'action': 'prepare-upload'});
    final uploadUrl = Uri.parse(_requiredString(prepared, 'uploadUrl'));
    final objectKey = _requiredString(prepared, 'objectKey');
    final request = http.StreamedRequest('PUT', uploadUrl)
      ..contentLength = attachment.byteSize
      ..headers.addAll({
        'content-type': attachment.mimeType,
        'x-amz-meta-sha256': attachment.sha256,
        'x-amz-meta-attachment-id': attachment.id,
        'x-amz-meta-user-id': attachment.userId ?? '',
      });
    await request.sink.addStream(bytes);
    await request.sink.close();
    final response = await _http.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('R2 upload failed with ${response.statusCode}');
    }

    final completed = await _invoke({...body, 'action': 'complete-upload'});
    final verifiedKey = _requiredString(completed, 'objectKey');
    if (verifiedKey != objectKey || completed['verified'] != true) {
      throw const FormatException('R2 verification response did not match.');
    }
    return objectKey;
  }

  Future<String> _uploadMultipart(
    Attachment attachment,
    File file,
  ) async {
    final body = _attachmentBody(attachment);
    // Fall back to single-part streaming if backend does not provide multipart actions
    try {
      final init = await _invoke({
        ...body,
        'action': 'create-multipart-upload',
      });
      final uploadId = _requiredString(init, 'uploadId');
      final parts = <Map<String, dynamic>>[];

      final fileSize = await file.length();
      var offset = 0;
      var partNumber = 1;

      while (offset < fileSize) {
        final end = (offset + multipartChunkSizeBytes).clamp(0, fileSize);
        final chunkStream = file.openRead(offset, end);
        final chunkBytes = await _readStreamBytes(chunkStream);

        final partPrep = await _invoke({
          ...body,
          'action': 'prepare-upload-part',
          'uploadId': uploadId,
          'partNumber': partNumber,
        });

        final partUrl = Uri.parse(_requiredString(partPrep, 'uploadUrl'));
        final putReq = http.Request('PUT', partUrl)
          ..bodyBytes = chunkBytes
          ..headers['content-type'] = attachment.mimeType;

        final putRes = await _http.send(putReq);
        if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
          throw HttpException(
            'Part $partNumber upload failed with ${putRes.statusCode}',
          );
        }
        final etag = putRes.headers['etag'] ?? '"part-$partNumber"';
        parts.add({'partNumber': partNumber, 'etag': etag});

        offset = end;
        partNumber++;
      }

      final completed = await _invoke({
        ...body,
        'action': 'complete-multipart-upload',
        'uploadId': uploadId,
        'parts': parts,
      });

      return _requiredString(completed, 'objectKey');
    } on Object {
      // Fallback to single-part stream upload if server unsupported
      return _uploadSinglePart(attachment, file.openRead());
    }
  }

  Future<Uint8List> _readStreamBytes(Stream<List<int>> stream) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  Future<String> download(
    Attachment attachment,
    AttachmentStorage storage,
  ) async {
    final downloadUrl = Uri.parse(await prepareDownloadUrl(attachment.id));
    final response = await _http.send(http.Request('GET', downloadUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('R2 download failed with ${response.statusCode}');
    }
    return storage.storeDownloaded(
      attachmentId: attachment.id,
      fileExtension: attachment.fileExtension,
      expectedByteSize: attachment.byteSize,
      expectedSha256: attachment.sha256,
      bytes: response.stream,
    );
  }

  Future<String> prepareDownloadUrl(String attachmentId) async {
    final prepared = await _invoke({
      'action': 'prepare-download',
      'attachmentId': attachmentId,
    });
    return _requiredString(prepared, 'downloadUrl');
  }

  Future<void> delete(String attachmentId) async {
    await _invoke({'action': 'delete', 'attachmentId': attachmentId});
  }

  Future<Map<String, dynamic>> _invoke(Map<String, Object?> body) async {
    final response = await _supabase.functions
        .invoke('attachment-storage', body: body)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'Edge function attachment-storage timed out after 15s',
          ),
        );
    if (response.status < 200 || response.status >= 300) {
      final errorMsg = response.data is Map &&
              (response.data as Map).containsKey('error')
          ? (response.data as Map)['error']
          : response.data?.toString() ??
              'Function returned HTTP ${response.status}';
      throw HttpException('Storage function error: $errorMsg');
    }
    final data = response.data;
    if (data is! Map) {
      throw FormatException(
        'Invalid attachment storage response (${response.status}): $data',
      );
    }
    final map = Map<String, dynamic>.from(data);
    if (map.containsKey('error') && map['error'] != null) {
      throw HttpException('Storage error: ${map['error']}');
    }
    return map;
  }

  Map<String, Object?> _attachmentBody(Attachment attachment) => {
    'attachmentId': attachment.id,
    'itemId': attachment.itemId,
    'originalFileName': attachment.originalFileName,
    'extension': attachment.fileExtension,
    'mimeType': attachment.mimeType,
    'byteSize': attachment.byteSize,
    'sha256': attachment.sha256,
  };

  String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing $key in attachment storage response.');
    }
    return value;
  }
}
