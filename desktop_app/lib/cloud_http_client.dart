import 'package:http/http.dart' as http;
import 'cloud_http_client_io.dart'
    if (dart.library.html) 'cloud_http_client_web.dart' as platform;

http.Client createCloudHttpClient() => platform.createCloudHttpClient();