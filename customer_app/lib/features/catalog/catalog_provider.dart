import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class CatalogState {
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;
  final String? selectedCategoryId;
  final String searchQuery;

  const CatalogState({
    this.categories = const [],
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategoryId,
    this.searchQuery = '',
  });

  CatalogState copyWith({
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
  }) =>
      CatalogState(
        categories: categories ?? this.categories,
        products: products ?? this.products,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        selectedCategoryId:
            clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class CatalogNotifier extends Notifier<CatalogState> {
  CatalogRepository get _repo => ref.read(catalogRepositoryProvider);

  @override
  CatalogState build() {
    _load();
    return const CatalogState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.getCategories(),
        _repo.getProducts(),
      ]);
      state = state.copyWith(
        categories: results[0] as List<CategoryModel>,
        products: results[1] as List<ProductModel>,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> filterByCategory(String? categoryId) async {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      isLoading: true,
      clearError: true,
    );
    try {
      final products = await _repo.getProducts(
        categoryId: categoryId,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, isLoading: true, clearError: true);
    try {
      final products = await _repo.getProducts(
        categoryId: state.selectedCategoryId,
        search: query.isEmpty ? null : query,
      );
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final catalogProvider =
    NotifierProvider<CatalogNotifier, CatalogState>(CatalogNotifier.new);

final productDetailProvider =
    FutureProvider.family<ProductModel, String>((ref, id) {
  return ref.read(catalogRepositoryProvider).getProduct(id);
});
