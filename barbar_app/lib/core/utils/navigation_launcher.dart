import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationLauncher {
  static Future<void> launchMapsNavigation({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String title,
  }) async {
    Uri uri;
    if (Platform.isAndroid) {
      uri = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
    } else if (Platform.isIOS) {
      uri = Uri.parse('https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d');
    } else {
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
    }

    try {
      bool launched = false;
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      
      if (!launched) {
        // Fallback to web Google Maps
        final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
        if (await canLaunchUrl(webUri)) {
          launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch map navigation for $title')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open map navigation: $e')),
        );
      }
    }
  }
}
