import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogState {
  final bool isLoading;
  final String? error;

  const CatalogState({this.isLoading = false, this.error});

  CatalogState copyWith({bool? isLoading, String? error}) => CatalogState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class CatalogNotifier extends Notifier<CatalogState> {
  @override
  CatalogState build() => const CatalogState();
}

final catalogProvider =
    NotifierProvider<CatalogNotifier, CatalogState>(CatalogNotifier.new);
