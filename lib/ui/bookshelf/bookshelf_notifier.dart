import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/database/daos/book_dao.dart';
import '../../constants/enums.dart';

final bookshelfNotifierProvider =
    StateNotifierProvider<BookshelfNotifier, BookshelfState>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return BookshelfNotifier(repository);
});

class BookshelfState {
  final List<Book> books;
  final bool isLoading;
  final String? error;
  final BookshelfViewMode viewMode;
  final BookSortType sortMode;
  final bool sortAscending;

  BookshelfState({
    required this.books,
    this.isLoading = false,
    this.error,
    this.viewMode = BookshelfViewMode.grid4,
    this.sortMode = BookSortType.recentRead,
    this.sortAscending = false,
  });

  BookshelfState copyWith({
    List<Book>? books,
    bool? isLoading,
    String? error,
    BookshelfViewMode? viewMode,
    BookSortType? sortMode,
    bool? sortAscending,
  }) {
    return BookshelfState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      viewMode: viewMode ?? this.viewMode,
      sortMode: sortMode ?? this.sortMode,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class BookshelfNotifier extends StateNotifier<BookshelfState> {
  final BookRepository _repository;

  BookshelfNotifier(this._repository)
      : super(BookshelfState(books: [])) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final books = await _repository.getAllBooks();
      state = state.copyWith(
        books: _sortBooks(books, state.sortMode, state.sortAscending),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addBook(Book book) async {
    try {
      await _repository.addBook(book);
      await loadBooks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteBook(String bookUrl) async {
    try {
      await _repository.deleteBook(bookUrl);
      await loadBooks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setViewMode(BookshelfViewMode view) {
    state = state.copyWith(viewMode: view);
  }

  void setSortMode(BookSortType sort) {
    if (state.sortMode == sort) {
      state = state.copyWith(
        sortAscending: !state.sortAscending,
        books: _sortBooks(state.books, sort, !state.sortAscending),
      );
    } else {
      state = state.copyWith(
        sortMode: sort,
        sortAscending: false,
        books: _sortBooks(state.books, sort, false),
      );
    }
  }

  List<Book> _sortBooks(List<Book> books, BookSortType sort, bool ascending) {
    final sorted = List<Book>.from(books);
    switch (sort) {
      case BookSortType.bookName:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case BookSortType.updateTime:
        sorted.sort((a, b) => b.latestChapterTime.compareTo(a.latestChapterTime));
      case BookSortType.recentRead:
        sorted.sort((a, b) => b.durChapterTime.compareTo(a.durChapterTime));
      case BookSortType.manual:
        sorted.sort((a, b) => a.order.compareTo(b.order));
    }
    if (ascending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }
}
