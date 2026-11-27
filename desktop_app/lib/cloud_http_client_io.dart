import 'dart:io';
import 'package:http/io_client.dart';

IOClient createCloudHttpClient() => IOClient(HttpClient());