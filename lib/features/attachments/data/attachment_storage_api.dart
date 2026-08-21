import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import 'attachment_storage.dart';

class AttachmentStorageApi {
  AttachmentStorageApi(this._supabase, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SupabaseClient _supabase;
  final http.Client _http;

  Future<String> upload(Attachment attachment, String absolutePath) async {
    return _upload(attachment, File(absolutePath).openRead());
  }

  Future<String> uploadBytes(Attachment attachment, Uint8List bytes) async {
    return _upload(attachment, Stream.value(bytes));
  }

  Future<String> _upload(Attachment attachment, Stream<List<int>> bytes) async {
    final body = _attachmentBody(attachment);
    final prepared = await _invoke({...body, 'action': 'prepare-upload'});
    final uploadUrl = Uri.parse(_requiredString(prepared, 'uploadUrl'));
    final objectKey = _requiredString(prepared, 'objectKey');
    final request = http.StreamedRequest('PUT', uploadUrl)
      ..contentLength = attachment.byteSize
      ..headers.addAll({'content-type': attachment.mimeType});
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
    final response = await _supabase.functions.invoke(
      'attachment-storage',
      body: body,
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid attachment storage response.');
    }
    return Map<String, dynamic>.from(data);
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
