import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> sendPanicSMS({
  required String name,
  required double latitude,
  required double longitude,
  required String phoneNumber,
}) async {
  final Uri functionUrl = Uri.parse(
    'https://us-central1-emergency-alert-system-e0a91.cloudfunctions.net/sendEmergencySMS',
  );

  final response = await http.post(
    functionUrl,
    headers: {'Content-Type': 'application/json'},
    body: '''
    {
      "name": "$name",
      "latitude": $latitude,
      "longitude": $longitude,
      "phone": "$phoneNumber"
    }
    ''',
  );

  if (response.statusCode == 200) {
    print('✅ SMS Sent');
  } else {
    print('❌ Failed to send SMS: ${response.statusCode} ${response.body}');
  }
}

Future<void> sendWhatsAppViaFirebaseFunction({
  required String name,
  required double latitude,
  required double longitude,
  required String phone,
}) async {
  final Uri url = Uri.parse(
    'https://us-central1-emergency-alert-system-e0a91.cloudfunctions.net/sendWhatsAppAlert',
  );

  final message =
      "🚨 Emergency Alert from $name!\n📍 https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'message': message}),
    );

    if (response.statusCode != 200) {
      print('❌ WhatsApp to $phone failed: ${response.body}');
    } else {
      print('✅ WhatsApp sent to $phone.');
    }
  } catch (e) {
    print('❌ Error sending to $phone: $e');
  }
}