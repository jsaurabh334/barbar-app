import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

class DeliveryGpsCalibrationScreen extends StatefulWidget {
  const DeliveryGpsCalibrationScreen({super.key});

  @override
  State<DeliveryGpsCalibrationScreen> createState() => _DeliveryGpsCalibrationScreenState();
}

class _DeliveryGpsCalibrationScreenState extends State<DeliveryGpsCalibrationScreen> {
  bool _calibrating = false;
  Position? _currentPosition;
  String _statusMessage = 'Ready for calibration';
  double _accuracyScore = 95.0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _calibrating = true;
      _statusMessage = 'Acquiring satellite lock...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _statusMessage = 'GPS Location services disabled. Enable in Settings.';
            _calibrating = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _accuracyScore = (pos.accuracy < 10) ? 98.0 : (pos.accuracy < 30 ? 85.0 : 65.0);
          _statusMessage = 'GPS Signal Calibrated! Accuracy: ±${pos.accuracy.toStringAsFixed(1)}m';
          _calibrating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'GPS calibration failed. Retrying...';
          _calibrating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Calibration', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: _calibrating ? null : (_accuracyScore / 100),
                          strokeWidth: 8,
                          color: _accuracyScore > 80 ? Colors.greenAccent : AppColors.primary,
                          backgroundColor: AppColors.surface,
                        ),
                      ),
                      Icon(
                        LucideIcons.navigation,
                        size: 40,
                        color: _accuracyScore > 80 ? Colors.greenAccent : AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_accuracyScore.toInt()}% Signal Quality',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: _accuracyScore > 80 ? Colors.greenAccent : AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _calibrating ? null : _fetchCurrentLocation,
                    icon: _calibrating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(LucideIcons.refreshCw, size: 18),
                    label: Text(_calibrating ? 'Calibrating...' : 'Recalibrate GPS Signal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('LIVE SENSOR DATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildDataTile('Latitude', _currentPosition != null ? _currentPosition!.latitude.toStringAsFixed(6) : '--', LucideIcons.mapPin),
            _buildDataTile('Longitude', _currentPosition != null ? _currentPosition!.longitude.toStringAsFixed(6) : '--', LucideIcons.mapPin),
            _buildDataTile('Accuracy', _currentPosition != null ? '±${_currentPosition!.accuracy.toStringAsFixed(1)} meters' : '--', LucideIcons.target),
            _buildDataTile('Altitude', _currentPosition != null ? '${_currentPosition!.altitude.toStringAsFixed(1)} m' : '--', LucideIcons.mountain),
            _buildDataTile('Speed', _currentPosition != null ? '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h' : '0.0 km/h', LucideIcons.gauge),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }
}
