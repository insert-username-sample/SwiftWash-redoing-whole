import 'package:flutter/material.dart';
import 'package:swiftwash_operator/services/audio_ring_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettingsWidget extends StatefulWidget {
  const AudioSettingsWidget({super.key});

  @override
  State<AudioSettingsWidget> createState() => _AudioSettingsWidgetState();
}

class _AudioSettingsWidgetState extends State<AudioSettingsWidget> {
  bool _isEnabled = true;
  double _volume = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = prefs.getString('audio_ring_settings');

      if (settings != null) {
        final data = Map<String, String>.from(
          settings.split(',').fold<Map<String, String>>({}, (map, pair) {
            final parts = pair.split(':');
            if (parts.length == 2) {
              map[parts[0]] = parts[1];
            }
            return map;
          })
        );

        setState(() {
          _isEnabled = data['enabled'] == 'true';
          _volume = double.tryParse(data['volume'] ?? '1.0') ?? 1.0;
        });
      }
    } catch (e) {
      debugPrint('Failed to load audio settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _isLoading = true);

      await AudioRingService.setEnabled(_isEnabled);
      await AudioRingService.setVolume(_volume);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Failed to save settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testRingtone() async {
    try {
      setState(() => _isLoading = true);

      await AudioRingService.testRingtone();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test ringtone played'),
        ),
      );
    } catch (e) {
      debugPrint('Failed to test ringtone: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to test ringtone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Audio Notification Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Enable/Disable Switch
            SwitchListTile(
              title: const Text('Enable Audio Notifications'),
              subtitle: const Text('Receive audio alerts for new orders'),
              value: _isEnabled,
              onChanged: (value) {
                setState(() => _isEnabled = value);
              },
            ),

            const SizedBox(height: 16),

            // Volume Slider
            ListTile(
              title: const Text('Notification Volume'),
              subtitle: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_volume * 100).round()}%',
                onChanged: (value) {
                  setState(() => _volume = value);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Test Ringtone Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testRingtone,
              icon: const Icon(Icons.volume_up),
              label: const Text('Test Ringtone'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 8),

            // Save Settings Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Status Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Audio Notification Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Status: ${AudioRingService.isEnabled ? 'Enabled' : 'Disabled'}'),
                  Text('Volume: ${(AudioRingService.volume * 100).round()}%'),
                  Text('Currently Ringing: ${AudioRingService.isRinging ? 'Yes' : 'No'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
