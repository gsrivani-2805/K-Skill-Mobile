import 'package:flutter/services.dart';

class PlatformAssets {
  static const MethodChannel _channel = MethodChannel('asset_loader');
  
  static Future<Uint8List?> loadAsset(String filename) async {
    try {
      final Uint8List result = await _channel.invokeMethod('loadAsset', filename);
      return result;
    } catch (e) {
      print('Failed to load asset: $e');
      return null;
    }
  }
}