import 'package:http/browser_client.dart';

BrowserClient createCloudHttpClient() => BrowserClient()..withCredentials = true;