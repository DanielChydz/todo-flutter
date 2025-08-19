import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherBannerMin extends StatefulWidget {
  const WeatherBannerMin({super.key, required this.apiKey});
  final String apiKey;

  @override
  State<WeatherBannerMin> createState() => _WeatherBannerMinState();
}

class _WeatherBannerMinState extends State<WeatherBannerMin> {
  late Future<_W> _f;

  @override
  void initState() {
    super.initState();
    _f = _load();
  }

  Future<_W> _load() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw 'Brak uprawnień do lokalizacji';
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': '${pos.latitude}',
      'lon': '${pos.longitude}',
      'appid': widget.apiKey,
      'units': 'metric',
      'lang': 'pl',
    });
    final r = await http.get(uri).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw 'API ${r.statusCode}';
    final j = jsonDecode(r.body) as Map<String, dynamic>;

    final city = (j['name'] as String?)?.trim();
    final temp = (j['main']['temp'] as num).toDouble();
    final desc = (j['weather'] as List).first['description'] as String;
    final icon = (j['weather'] as List).first['icon'] as String;
    return _W(
      city?.isEmpty ?? true ? 'Twoja lokalizacja' : city!,
      temp,
      desc,
      icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_W>(
      future: _f,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return _box(
            child: const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (s.hasError) {
          return _box(
            child: Row(
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(width: 8),
                Expanded(child: Text('Pogoda niedostępna: ${s.error}')),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => _f = _load()),
                ),
              ],
            ),
          );
        }
        final w = s.data!;
        return _box(
          child: Row(
            children: [
              Image.network(
                'https://openweathermap.org/img/wn/${w.icon}@2x.png',
                width: 48,
                height: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.city,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(w.desc, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${w.temp.round()}°C',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => _f = _load()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _box({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
    child: child,
  );
}

class _W {
  _W(this.city, this.temp, this.desc, this.icon);
  final String city, desc, icon;
  final double temp;
}
