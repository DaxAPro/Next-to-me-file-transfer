import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/models/chat_message.dart';
import '../storage/local_chat_storage.dart';

class LocalPortalEndpoint {
  final String address;
  final int port;

  const LocalPortalEndpoint({required this.address, required this.port});

  Uri get uri => Uri(scheme: 'http', host: address, port: port);
}

class LocalWebServerService {
  static const int defaultPort = 8080;
  static const int maximumUploadBytes = 2 * 1024 * 1024 * 1024;
  static const MethodChannel _platformChannel = MethodChannel(
    'nexttome/wifi_direct',
  );
  static const String _serviceType = '_http._tcp.local';
  static const String _instanceName = 'NextToMe.$_serviceType';
  static final LocalWebServerService instance = LocalWebServerService._();
  static const Uuid _uuid = Uuid();

  final StreamController<ChatMessage> _chatController =
      StreamController<ChatMessage>.broadcast();
  final Set<WebSocketChannel> _webSocketClients = {};
  final Set<String> _pendingPortalMessageIds = {};
  final _MdnsAdvertiser _advertiser = _MdnsAdvertiser();

  HttpServer? _server;
  Directory? _uploadDirectory;
  String? _accessToken;
  List<InternetAddress> _localAddresses = const [];
  Future<void> Function(Map<String, dynamic>)? _onPortalChatMessage;
  int _port = defaultPort;
  bool _multicastLockAcquired = false;
  String? mdnsError;

  LocalWebServerService._();

  bool get isRunning => _server != null;
  int get port => _port;
  int get connectedBrowserCount => _webSocketClients.length;
  Stream<ChatMessage> get chatStream => _chatController.stream;

  String? get accessUrl {
    final token = _accessToken;
    if (!isRunning || token == null) return null;
    final host = mdnsError == null
        ? 'nexttome.local'
        : _localAddresses.isEmpty
        ? null
        : _localAddresses.first.address;
    if (host == null) return null;
    return Uri(
      scheme: 'http',
      host: host,
      port: _port,
      path: '/',
      queryParameters: {'token': token},
    ).toString();
  }

  Future<void> start({
    int port = defaultPort,
    Future<void> Function(Map<String, dynamic>)? onPortalChatMessage,
  }) async {
    if (isRunning) {
      _onPortalChatMessage = onPortalChatMessage ?? _onPortalChatMessage;
      return;
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final uploadDirectory = Directory(
      path.join(supportDirectory.path, 'nexttome_portal_uploads'),
    );
    await uploadDirectory.create(recursive: true);

    if (Platform.isAndroid) {
      await _platformChannel.invokeMethod<void>('acquireMulticastLock');
      _multicastLockAcquired = true;
    }
    late final HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } catch (_) {
      await _releaseMulticastLock();
      rethrow;
    }
    _uploadDirectory = uploadDirectory;
    _accessToken = _uuid.v4();
    _port = server.port;
    _onPortalChatMessage = onPortalChatMessage;
    _server = server;
    shelf_io.serveRequests(server, _handleRequest, poweredByHeader: null);

    mdnsError = null;
    try {
      _localAddresses = await _localIpv4Addresses();
      if (_localAddresses.isEmpty) {
        await stop();
        throw StateError(
          'Connect to a local Wi-Fi network or hotspot before starting the portal.',
        );
      }
      await _advertiser.start(port: _port, addresses: _localAddresses);
    } on SocketException catch (error) {
      await _advertiser.stop();
      mdnsError = 'mDNS is unavailable on this network: $error';
    } on OSError catch (error) {
      await _advertiser.stop();
      mdnsError = 'mDNS is unavailable on this network: $error';
    }
  }

  Future<void> stop() async {
    final server = _server;
    try {
      await _advertiser.stop();
    } finally {
      _server = null;
      _accessToken = null;
      _localAddresses = const [];
      _onPortalChatMessage = null;
      try {
        await _releaseMulticastLock();
      } finally {
        if (server != null) await server.close(force: true);
        for (final channel in _webSocketClients.toList(growable: false)) {
          await channel.sink.close();
        }
        _webSocketClients.clear();
      }
    }
  }

  Future<void> _releaseMulticastLock() async {
    if (!_multicastLockAcquired) return;
    _multicastLockAcquired = false;
    await _platformChannel.invokeMethod<void>('releaseMulticastLock');
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    if (!_isAuthorized(request)) {
      return shelf.Response(
        HttpStatus.unauthorized,
        body: 'This portal link is invalid or has expired.',
        headers: const {'content-type': 'text/plain; charset=utf-8'},
      );
    }

    if (request.url.path == 'ws') {
      return _webSocketHandler(request);
    }
    if (request.url.path == '' && request.method == 'GET') {
      return shelf.Response.ok(
        _portalHtml,
        headers: _securityHeaders('text/html; charset=utf-8'),
      );
    }
    if (request.url.path == 'api/files' && request.method == 'GET') {
      return _listFiles();
    }
    if (request.url.path == 'api/upload' && request.method == 'POST') {
      return _uploadFile(request);
    }
    if (request.url.pathSegments.length == 3 &&
        request.url.pathSegments[0] == 'api' &&
        request.url.pathSegments[1] == 'download' &&
        request.method == 'GET') {
      return _downloadFile(request.url.pathSegments[2]);
    }
    if (request.url.pathSegments.length == 3 &&
        request.url.pathSegments[0] == 'api' &&
        request.url.pathSegments[1] == 'files' &&
        request.method == 'DELETE') {
      return _deleteFile(request.url.pathSegments[2]);
    }
    return shelf.Response.notFound('Not found.');
  }

  bool _isAuthorized(shelf.Request request) {
    final token = _accessToken;
    final suppliedToken = request.url.queryParameters['token'];
    if (token == null || suppliedToken == null) return false;
    if (token.length != suppliedToken.length) return false;
    var difference = 0;
    for (var index = 0; index < token.length; index++) {
      difference |= token.codeUnitAt(index) ^ suppliedToken.codeUnitAt(index);
    }
    return difference == 0;
  }

  shelf.Handler get _webSocketHandler => webSocketHandler((channel, protocol) {
    _webSocketClients.add(channel);
    channel.sink.add(jsonEncode({'type': 'connected'}));
    channel.stream.listen(
      (dynamic data) {
        unawaited(_handleWebSocketData(channel, data));
      },
      onError: (Object error, StackTrace stackTrace) {
        _webSocketClients.remove(channel);
      },
      onDone: () {
        _webSocketClients.remove(channel);
      },
      cancelOnError: true,
    );
  }, pingInterval: const Duration(seconds: 30));

  Future<void> _handleWebSocketData(
    WebSocketChannel channel,
    dynamic data,
  ) async {
    try {
      if (data is! String || data.length > 8192) {
        throw const FormatException('Chat messages must be short text.');
      }
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('The chat message format is invalid.');
      }
      final content = decoded['content']?.toString().trim() ?? '';
      if (content.isEmpty || content.length > 2000) {
        throw const FormatException(
          'Enter a message between 1 and 2000 characters.',
        );
      }
      final senderName = _sanitizeDisplayName(
        decoded['senderName']?.toString() ?? '',
      );
      final message = ChatMessage(
        id: 'portal-${_uuid.v4()}',
        senderId: 'portal-client-${_uuid.v4()}',
        senderName: senderName,
        content: content,
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.delivered,
      );

      await LocalChatStorage.instance.saveMessage(message);
      if (!_chatController.isClosed) _chatController.add(message);
      _broadcast({'type': 'chat', 'message': message.toJson()});

      _pendingPortalMessageIds.add(message.id);
      Timer(const Duration(seconds: 30), () {
        _pendingPortalMessageIds.remove(message.id);
      });
      try {
        await _onPortalChatMessage?.call(message.toJson());
      } catch (error) {
        _pendingPortalMessageIds.remove(message.id);
        channel.sink.add(
          jsonEncode({
            'type': 'notice',
            'message':
                'Saved on this phone, but could not forward to nearby app peers: $error',
          }),
        );
      }
    } on FormatException catch (error) {
      channel.sink.add(jsonEncode({'type': 'error', 'message': error.message}));
    } catch (error) {
      channel.sink.add(
        jsonEncode({
          'type': 'error',
          'message': 'Could not save chat message: $error',
        }),
      );
    }
  }

  void publishChatMessage(Map<String, dynamic> message) {
    final id = message['id']?.toString();
    if (id != null && _pendingPortalMessageIds.remove(id)) return;
    if (!isRunning) return;
    _broadcast({'type': 'chat', 'message': message});
  }

  void _broadcast(Map<String, dynamic> payload) {
    final encoded = jsonEncode(payload);
    for (final client in _webSocketClients.toList(growable: false)) {
      try {
        client.sink.add(encoded);
      } on StateError {
        _webSocketClients.remove(client);
      }
    }
  }

  shelf.Response _securityResponse(
    int statusCode, {
    Object? body,
    String contentType = 'application/json; charset=utf-8',
  }) {
    return shelf.Response(
      statusCode,
      body: body,
      headers: _securityHeaders(contentType),
    );
  }

  Map<String, String> _securityHeaders(String contentType) => {
    'content-type': contentType,
    'x-content-type-options': 'nosniff',
    'referrer-policy': 'no-referrer',
    'cache-control': 'no-store',
    'content-security-policy':
        "default-src 'self'; connect-src 'self' ws:; style-src 'unsafe-inline'; "
        "script-src 'unsafe-inline'; img-src 'self' data:; form-action 'self'; "
        "base-uri 'none'; frame-ancestors 'none'",
  };

  Future<shelf.Response> _listFiles() async {
    final files = await _portalFiles();
    return _securityResponse(
      HttpStatus.ok,
      body: jsonEncode([
        for (final entry in files)
          {
            'id': entry.id,
            'name': entry.name,
            'size': await entry.file.length(),
          },
      ]),
    );
  }

  Future<shelf.Response> _uploadFile(shelf.Request request) async {
    final contentLength = request.contentLength;
    if (contentLength != null &&
        contentLength > maximumUploadBytes + 1024 * 1024) {
      return _securityResponse(
        HttpStatus.requestEntityTooLarge,
        body: jsonEncode({'error': 'Files cannot exceed 2 GB.'}),
      );
    }
    final form = request.formData();
    if (form == null) {
      return _securityResponse(
        HttpStatus.badRequest,
        body: jsonEncode({'error': 'Use a multipart form to upload a file.'}),
      );
    }

    final uploadId = _uuid.v4();
    File? targetFile;
    IOSink? sink;
    var receivedBytes = 0;
    String? originalName;
    try {
      await for (final field in form.formData) {
        if (field.name != 'file' || field.filename == null) {
          await field.part.drain<void>();
          continue;
        }
        if (targetFile != null) {
          await field.part.drain<void>();
          throw const FormatException('Upload one file at a time.');
        }
        originalName = _sanitizeFilename(field.filename!);
        targetFile = File(
          path.join(_uploadDirectory!.path, '$uploadId--$originalName'),
        );
        sink = targetFile.openWrite();
        await for (final chunk in field.part) {
          receivedBytes += chunk.length;
          if (receivedBytes > maximumUploadBytes) {
            throw const _UploadTooLargeException();
          }
          sink.add(chunk);
        }
      }
      if (targetFile == null || sink == null || originalName == null) {
        return _securityResponse(
          HttpStatus.badRequest,
          body: jsonEncode({'error': 'Choose a file to upload.'}),
        );
      }
      await sink.flush();
      await sink.close();
      return _securityResponse(
        HttpStatus.created,
        body: jsonEncode({
          'id': uploadId,
          'name': originalName,
          'size': receivedBytes,
        }),
      );
    } on _UploadTooLargeException {
      await sink?.close();
      if (targetFile != null && await targetFile.exists()) {
        await targetFile.delete();
      }
      return _securityResponse(
        HttpStatus.requestEntityTooLarge,
        body: jsonEncode({'error': 'Files cannot exceed 2 GB.'}),
      );
    } on FormatException catch (error) {
      await sink?.close();
      if (targetFile != null && await targetFile.exists()) {
        await targetFile.delete();
      }
      return _securityResponse(
        HttpStatus.badRequest,
        body: jsonEncode({'error': error.message}),
      );
    } catch (error) {
      await sink?.close();
      if (targetFile != null && await targetFile.exists()) {
        await targetFile.delete();
      }
      return _securityResponse(
        HttpStatus.internalServerError,
        body: jsonEncode({
          'error': 'Could not store the uploaded file: $error',
        }),
      );
    }
  }

  Future<shelf.Response> _downloadFile(String id) async {
    if (!_isValidId(id)) return shelf.Response.notFound('File not found.');
    final file = await _findFile(id);
    if (file == null) return shelf.Response.notFound('File not found.');
    final name = _fileNameFromStored(file.uri.pathSegments.last);
    return shelf.Response.ok(
      file.openRead(),
      headers: {
        ..._securityHeaders('application/octet-stream'),
        'content-length': '${await file.length()}',
        'content-disposition':
            'attachment; filename="download"; filename*=UTF-8\'\'${Uri.encodeComponent(name)}',
      },
      context: const {'shelf.io.buffer_output': false},
    );
  }

  Future<shelf.Response> _deleteFile(String id) async {
    if (!_isValidId(id)) return shelf.Response.notFound('File not found.');
    final file = await _findFile(id);
    if (file == null) return shelf.Response.notFound('File not found.');
    await file.delete();
    return _securityResponse(HttpStatus.noContent);
  }

  Future<List<_PortalFile>> _portalFiles() async {
    final directory = _uploadDirectory;
    if (directory == null || !await directory.exists()) return [];
    final entries = <_PortalFile>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final storedName = path.basename(entity.path);
      final separator = storedName.indexOf('--');
      if (separator <= 0) continue;
      final id = storedName.substring(0, separator);
      if (!_isValidId(id)) continue;
      entries.add(
        _PortalFile(
          id: id,
          name: _fileNameFromStored(storedName),
          file: entity,
        ),
      );
    }
    entries.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return entries;
  }

  Future<File?> _findFile(String id) async {
    final files = await _portalFiles();
    for (final entry in files) {
      if (entry.id == id) return entry.file;
    }
    return null;
  }

  static String _sanitizeFilename(String input) {
    final leaf = input.split(RegExp(r'[/\\]')).last.trim();
    final safe = leaf
        .replaceAll(RegExp(r'[\x00-\x1F\x7F<>:"|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (safe.isEmpty || safe == '.' || safe == '..') return 'shared-file';
    return safe.length > 180 ? safe.substring(0, 180) : safe;
  }

  static String _sanitizeDisplayName(String input) {
    final safe = input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (safe.isEmpty) return 'Nearby computer';
    return safe.length > 32 ? safe.substring(0, 32) : safe;
  }

  static String _fileNameFromStored(String storedName) {
    final separator = storedName.indexOf('--');
    return separator < 0 ? storedName : storedName.substring(separator + 2);
  }

  static bool _isValidId(String id) =>
      RegExp(r'^[a-f0-9-]{36}$', caseSensitive: false).hasMatch(id);

  Future<List<InternetAddress>> _localIpv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    final addresses = <InternetAddress>{};
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final bytes = address.rawAddress;
        final isPrivate =
            bytes[0] == 10 ||
            (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
            (bytes[0] == 192 && bytes[1] == 168);
        if (isPrivate) addresses.add(address);
      }
    }
    return addresses.toList(growable: false);
  }

  static Future<List<LocalPortalEndpoint>> discoverNearbyPortals({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final client = MDnsClient();
    final endpoints = <String, LocalPortalEndpoint>{};
    await client.start();
    try {
      await for (final pointer
          in client
              .lookup<PtrResourceRecord>(
                ResourceRecordQuery.serverPointer(_serviceType),
              )
              .timeout(timeout, onTimeout: (sink) => sink.close())) {
        if (!pointer.domainName.startsWith('NextToMe.')) continue;
        await for (final service
            in client
                .lookup<SrvResourceRecord>(
                  ResourceRecordQuery.service(pointer.domainName),
                )
                .timeout(timeout, onTimeout: (sink) => sink.close())) {
          await for (final address
              in client
                  .lookup<IPAddressResourceRecord>(
                    ResourceRecordQuery.addressIPv4(service.target),
                  )
                  .timeout(timeout, onTimeout: (sink) => sink.close())) {
            final endpoint = LocalPortalEndpoint(
              address: address.address.address,
              port: service.port,
            );
            endpoints[endpoint.uri.toString()] = endpoint;
          }
        }
      }
    } finally {
      client.stop();
    }
    return endpoints.values.toList(growable: false);
  }

  static const String _portalHtml = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>NextToMe Local Portal</title>
<style>
:root{color-scheme:light;--green:#10b981;--cyan:#00b8d9;--ink:#17231f;--muted:#61736b;--line:#dce9e3;--surface:#fff;--bg:#f4faf7}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px system-ui,-apple-system,Segoe UI,sans-serif}
header{background:var(--surface);border-bottom:1px solid var(--line);padding:20px max(20px,calc((100vw - 980px)/2));display:flex;align-items:center;justify-content:space-between}
h1{font-size:20px;margin:0}header p{margin:4px 0 0;color:var(--muted);font-size:13px}.badge{color:#087a55;background:#e6f8ef;border:1px solid #bdebd3;padding:6px 10px;border-radius:20px;font-size:12px}
main{max-width:980px;margin:24px auto;padding:0 18px;display:grid;grid-template-columns:1.15fr .85fr;gap:18px}.card{background:var(--surface);border:1px solid var(--line);border-radius:16px;padding:20px;box-shadow:0 8px 26px #0e4b2b0a}
h2{font-size:16px;margin:0 0 14px}.upload{border:1px dashed #91cdb0;border-radius:12px;padding:18px;background:#f8fcf9}input,button{font:inherit}input[type=file]{width:100%;margin:12px 0}button,.button{border:0;border-radius:9px;background:var(--green);color:white;padding:10px 14px;font-weight:650;cursor:pointer;text-decoration:none}button:disabled{opacity:.55;cursor:wait}.muted{color:var(--muted);font-size:13px}.files{width:100%;border-collapse:collapse}.files td{padding:10px 4px;border-bottom:1px solid var(--line);font-size:13px}.files td:last-child{text-align:right;white-space:nowrap}.files button{padding:6px 9px;margin-left:5px;font-size:12px;background:#e9f8f0;color:#087a55}
.chat{height:320px;overflow:auto;background:#f8fcf9;border:1px solid var(--line);border-radius:12px;padding:10px}.bubble{margin:7px 0;padding:9px 11px;background:#eaf7f0;border-radius:10px;overflow-wrap:anywhere}.bubble strong{display:block;color:#087a55;font-size:12px;margin-bottom:3px}.bubble.notice{background:#e8f8fb;color:#08758a}.chat-form{display:flex;gap:8px;margin-top:10px}.chat-form input{flex:1;min-width:0;border:1px solid var(--line);border-radius:9px;padding:10px}.status{min-height:20px;margin:8px 0 0;color:var(--muted);font-size:12px}
@media(max-width:700px){main{grid-template-columns:1fr;margin-top:14px}header{padding:16px 18px}}
</style>
</head>
<body>
<header><div><h1>NextToMe</h1><p>Private file sharing on your local network</p></div><span class="badge">Local connection</span></header>
<main>
<section class="card"><h2>Files on this device</h2><form id="upload" class="upload"><label for="file">Choose a file to send to the phone</label><input id="file" name="file" type="file" required><button id="uploadButton" type="submit">Upload file</button><p id="uploadStatus" class="status"></p></form><h2 style="margin-top:22px">Shared files</h2><table class="files"><tbody id="fileList"><tr><td class="muted">Loading files...</td></tr></tbody></table></section>
<section class="card"><h2>Group chat</h2><p class="muted">Messages are shared with connected NextToMe peers when available.</p><div id="chat" class="chat" aria-live="polite"></div><form id="chatForm" class="chat-form"><input id="name" maxlength="32" placeholder="Your name" aria-label="Your name"><input id="message" maxlength="2000" placeholder="Write a message" aria-label="Message" required><button type="submit">Send</button></form><p id="chatStatus" class="status">Connecting to local chat...</p></section>
</main>
<script>
const token=new URLSearchParams(location.search).get('token')||'';
const api=(path)=>path+'?token='+encodeURIComponent(token);
const fileList=document.getElementById('fileList');
const chat=document.getElementById('chat');
const uploadStatus=document.getElementById('uploadStatus');
const chatStatus=document.getElementById('chatStatus');
function addChat(name,text,notice=false){const item=document.createElement('div');item.className='bubble'+(notice?' notice':'');const sender=document.createElement('strong');sender.textContent=name;const body=document.createElement('span');body.textContent=text;item.append(sender,body);chat.append(item);chat.scrollTop=chat.scrollHeight}
async function loadFiles(){try{const response=await fetch(api('/api/files'));if(!response.ok)throw new Error('Could not load files');const files=await response.json();fileList.replaceChildren();if(!files.length){const row=document.createElement('tr');row.innerHTML='<td class="muted">No files have been shared yet.</td>';fileList.append(row);return}for(const file of files){const row=document.createElement('tr');const name=document.createElement('td');name.textContent=file.name+' · '+(file.size/1048576).toFixed(2)+' MB';const actions=document.createElement('td');const download=document.createElement('a');download.className='button';download.textContent='Download';download.href=api('/api/download/'+encodeURIComponent(file.id));download.setAttribute('download',file.name);const remove=document.createElement('button');remove.textContent='Delete';remove.onclick=async()=>{const result=await fetch(api('/api/files/'+encodeURIComponent(file.id)),{method:'DELETE'});if(result.ok)loadFiles()};actions.append(download,remove);row.append(name,actions);fileList.append(row)}}catch(error){fileList.textContent=error.message}}
document.getElementById('upload').addEventListener('submit',async(event)=>{event.preventDefault();const input=document.getElementById('file');if(!input.files.length)return;const button=document.getElementById('uploadButton');button.disabled=true;uploadStatus.textContent='Uploading...';try{const form=new FormData();form.append('file',input.files[0]);const response=await fetch(api('/api/upload'),{method:'POST',body:form});const result=await response.json();if(!response.ok)throw new Error(result.error||'Upload failed');uploadStatus.textContent='Upload complete';input.value='';await loadFiles()}catch(error){uploadStatus.textContent=error.message}finally{button.disabled=false}});
document.getElementById('chatForm').addEventListener('submit',(event)=>{event.preventDefault();const input=document.getElementById('message');const text=input.value.trim();if(!text||socket.readyState!==WebSocket.OPEN)return;socket.send(JSON.stringify({content:text,senderName:document.getElementById('name').value.trim()}));input.value=''});
const wsUrl=new URL('/ws',location.href);wsUrl.protocol=location.protocol==='https:'?'wss:':'ws:';wsUrl.searchParams.set('token',token);const socket=new WebSocket(wsUrl);
socket.onopen=()=>chatStatus.textContent='Connected';socket.onclose=()=>chatStatus.textContent='Disconnected from local chat';socket.onerror=()=>chatStatus.textContent='Chat connection error';socket.onmessage=(event)=>{try{const data=JSON.parse(event.data);if(data.type==='chat'){const message=data.message;addChat(message.senderName||'Nearby device',message.content||'')}else if(data.type==='notice'||data.type==='error'){addChat('NextToMe',data.message,true)}}catch(error){chatStatus.textContent='Received an invalid chat message'}};
loadFiles();
</script>
</body>
</html>''';
}

class _PortalFile {
  final String id;
  final String name;
  final File file;

  const _PortalFile({required this.id, required this.name, required this.file});
}

class _UploadTooLargeException implements Exception {
  const _UploadTooLargeException();
}

class _MdnsAdvertiser {
  static final InternetAddress _multicastAddress = InternetAddress(
    '224.0.0.251',
  );
  static const int _dnsPort = 5353;
  static const int _ttlSeconds = 120;
  RawDatagramSocket? _socket;
  Timer? _announcementTimer;
  List<InternetAddress> _addresses = const [];
  int _port = LocalWebServerService.defaultPort;

  Future<void> start({
    required int port,
    required List<InternetAddress> addresses,
  }) async {
    _port = port;
    _addresses = addresses;
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _dnsPort,
      reuseAddress: true,
      reusePort: true,
    );
    _socket = socket;
    socket.joinMulticast(_multicastAddress);
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      while (true) {
        final datagram = socket.receive();
        if (datagram == null) break;
        if (datagram.data.length >= 4 &&
            (datagram.data[2] & 0x80) == 0 &&
            _isRelevantQuery(datagram.data)) {
          _announce();
        }
      }
    });
    _announce();
    _announcementTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _announce(),
    );
  }

  Future<void> stop() async {
    _announce(goodbye: true);
    _announcementTimer?.cancel();
    _announcementTimer = null;
    _socket?.close();
    _socket = null;
  }

  bool _isRelevantQuery(List<int> packet) {
    final text = String.fromCharCodes(packet).toLowerCase();
    return text.contains('_http') || text.contains('nexttome');
  }

  void _announce({bool goodbye = false}) {
    final socket = _socket;
    if (socket == null) return;
    final packet = _buildResponse(goodbye: goodbye);
    socket.send(packet, _multicastAddress, _dnsPort);
  }

  Uint8List _buildResponse({bool goodbye = false}) {
    final records = <Uint8List>[];
    records.add(
      _resourceRecord(
        owner: '_http._tcp.local',
        type: 12,
        cacheFlush: false,
        goodbye: goodbye,
        data: _encodeName(LocalWebServerService._instanceName),
      ),
    );
    final srvData = BytesBuilder();
    final srvHead = ByteData(6)
      ..setUint16(0, 0)
      ..setUint16(2, 0)
      ..setUint16(4, _port);
    srvData.add(srvHead.buffer.asUint8List());
    srvData.add(_encodeName('nexttome.local'));
    records.add(
      _resourceRecord(
        owner: LocalWebServerService._instanceName,
        type: 33,
        cacheFlush: true,
        goodbye: goodbye,
        data: srvData.takeBytes(),
      ),
    );
    final txtValue = Uint8List.fromList(utf8.encode('nexttome=1'));
    records.add(
      _resourceRecord(
        owner: LocalWebServerService._instanceName,
        type: 16,
        cacheFlush: true,
        goodbye: goodbye,
        data: Uint8List.fromList([txtValue.length, ...txtValue]),
      ),
    );
    for (final address in _addresses) {
      records.add(
        _resourceRecord(
          owner: 'nexttome.local',
          type: 1,
          cacheFlush: true,
          goodbye: goodbye,
          data: Uint8List.fromList(address.rawAddress),
        ),
      );
    }

    final header = ByteData(12)
      ..setUint16(0, 0)
      ..setUint16(2, 0x8400)
      ..setUint16(4, 0)
      ..setUint16(6, records.length)
      ..setUint16(8, 0)
      ..setUint16(10, 0);
    final packet = BytesBuilder()..add(header.buffer.asUint8List());
    for (final record in records) {
      packet.add(record);
    }
    return packet.takeBytes();
  }

  Uint8List _resourceRecord({
    required String owner,
    required int type,
    required bool cacheFlush,
    required bool goodbye,
    required Uint8List data,
  }) {
    final header = ByteData(10)
      ..setUint16(0, type)
      ..setUint16(2, cacheFlush ? 0x8001 : 1)
      ..setUint32(4, goodbye ? 0 : _ttlSeconds)
      ..setUint16(8, data.length);
    return Uint8List.fromList([
      ..._encodeName(owner),
      ...header.buffer.asUint8List(),
      ...data,
    ]);
  }

  Uint8List _encodeName(String name) {
    final result = BytesBuilder();
    for (final label in name.split('.')) {
      final encoded = utf8.encode(label);
      result.add([encoded.length, ...encoded]);
    }
    result.addByte(0);
    return result.takeBytes();
  }
}
