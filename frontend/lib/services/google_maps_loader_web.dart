import 'dart:async';
import 'dart:html' as html;
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;

class GoogleMapsLoader {
  static bool _ready = false;
  static Completer<bool>? _completer;

  static bool get isReady => _ready;

  static Future<bool> ensureLoaded(String apiKey) {
    if (_ready) return Future.value(true);
    final resolvedKey = _resolveApiKey(apiKey);
    if (resolvedKey == null) {
      return Future.value(false);
    }
    if (_hasGoogleMaps()) {
      _ready = true;
      return Future.value(true);
    }
    if (_completer != null) return _completer!.future;

    _completer = Completer<bool>();

    final existing = html.document.querySelector(
      'script[data-google-maps="true"]',
    );
    if (existing == null) {
      final script = html.ScriptElement()
        ..src =
            'https://maps.googleapis.com/maps/api/js?key=$resolvedKey&libraries=places'
        ..async = true
        ..defer = true;
      script.dataset['googleMaps'] = 'true';
      script.onError.listen((_) => _complete(false));
      script.onLoad.listen((_) => _complete(_hasGoogleMaps()));
      html.document.head?.append(script);
    }

    _waitForGoogleMaps();
    return _completer!.future;
  }

  static String? _resolveApiKey(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.isNotEmpty && trimmed != 'YOUR_GOOGLE_MAPS_API_KEY') {
      return trimmed;
    }

    final meta = html.document.querySelector(
      'meta[name="google-maps-api-key"]',
    );
    final metaKey = meta?.getAttribute('content')?.trim();
    if (metaKey != null &&
        metaKey.isNotEmpty &&
        metaKey != 'YOUR_GOOGLE_MAPS_API_KEY') {
      return metaKey;
    }

    final stored = html.window.localStorage['google_maps_api_key']?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    return null;
  }

  static void _waitForGoogleMaps() {
    int attempts = 0;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      attempts += 1;
      if (_hasGoogleMaps()) {
        timer.cancel();
        _complete(true);
        return;
      }
      if (attempts >= 50) {
        timer.cancel();
        _complete(false);
      }
    });
  }

  static bool _hasGoogleMaps() {
    if (!js_util.hasProperty(html.window, 'google')) return false;
    final google = js_util.getProperty(html.window, 'google');
    return js_util.hasProperty(google, 'maps');
  }

  static void _complete(bool value) {
    if (_completer == null || _completer!.isCompleted) return;
    _ready = value;
    _completer!.complete(value);
    _completer = null;
  }
}
