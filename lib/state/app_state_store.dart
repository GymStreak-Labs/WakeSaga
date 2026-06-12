import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';

class AppStateStore {
  AppStateStore._(this._prefs);

  static const _snapshotKey = 'wakeSaga.appState.v1';

  final SharedPreferences _prefs;
  AppState? _boundState;
  Timer? _debounce;

  static Future<AppStateStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStateStore._(prefs);
  }

  AppState loadState() {
    final state = AppState();
    final raw = _prefs.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) return state;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, Object?>) {
        state.restoreFromJson(data);
      } else if (data is Map) {
        state.restoreFromJson(Map<String, Object?>.from(data));
      }
    } catch (_) {
      // Corrupt local state should never brick the alarm app. Keep defaults.
    }
    return state;
  }

  void bind(AppState state) {
    if (_boundState == state) return;
    _boundState?.removeListener(_queueSave);
    _boundState = state;
    state.addListener(_queueSave);
    _queueSave();
  }

  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    final state = _boundState;
    if (state == null) return;
    await _prefs.setString(_snapshotKey, jsonEncode(state.toJson()));
  }

  void dispose() {
    _debounce?.cancel();
    _boundState?.removeListener(_queueSave);
    _boundState = null;
  }

  void _queueSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      unawaited(flush());
    });
  }
}
