import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/shipment/data/datasources/places_datasource.dart';
import 'package:customer_app/features/shipment/domain/models/place_suggestion.dart';

/// State for the address search screen.
class AddressSearchState {
  const AddressSearchState({
    this.query = '',
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<PlaceSuggestion> suggestions;
  final bool isLoading;
  final String? error;

  AddressSearchState copyWith({
    String? query,
    List<PlaceSuggestion>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return AddressSearchState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages address search with debouncing.
///
/// Debouncing: waits 400ms after the user stops typing before
/// calling the Places API. Without it, every keystroke fires an
/// API call — 11 calls for "Kampala Road" instead of 1-2.
/// 400ms is the industry standard debounce for search inputs.
class AddressSearchNotifier extends AutoDisposeNotifier<AddressSearchState> {
  Timer? _debounceTimer;
  late PlacesDatasource _datasource;

  @override
  AddressSearchState build() {
    _datasource = PlacesDatasource();
    ref.onDispose(() => _debounceTimer?.cancel());
    return const AddressSearchState();
  }

  void onQueryChanged(String query) {
    // Cancel previous timer — reset debounce
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      state = const AddressSearchState();
      return;
    }

    // Show loading immediately for responsive feel
    state = state.copyWith(query: query, isLoading: true);

    // Wait 400ms then call the API
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      await _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final suggestions =
          await _datasource.getAutocompleteSuggestions(query);
      state = state.copyWith(
        suggestions: suggestions,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load suggestions. Check your connection.',
      );
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = const AddressSearchState();
  }
}

final addressSearchProvider =
    AutoDisposeNotifierProvider<AddressSearchNotifier, AddressSearchState>(
  () => AddressSearchNotifier(),
);

final placesDatasourceProvider = Provider.autoDispose<PlacesDatasource>(
  (ref) => PlacesDatasource(),
);
