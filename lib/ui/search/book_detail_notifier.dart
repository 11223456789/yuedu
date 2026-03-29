import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/database/tables/books_table.dart';
import '../../model/web_book/web_book.dart';

final bookDetailNotifierProvider = StateNotifierProvider.family<
    BookDetailNotifier, BookDetailState, String>((ref, bookUrl) {
  final repository = ref.watch(bookRepositoryProvider);
  return BookDetailNotifier(repository, bookUrl);
});

class BookDetailState {
  final Book? localBook;
  final WebBook? webBook;
  final bool isLoading;
  final String? error;
  final bool isInShelf;

  BookDetailState({
    this.localBook,
    this.webBook,
    this.isLoading = false,
    this.error,
    this.isInShelf = false,
  });

  BookDetailState copyWith({
    Book? localBook,
    WebBook? webBook,
    bool? isLoading,
    String? error,
    bool? isInShelf,
  }) {
    return BookDetailState(
      localBook: localBook ?? this.localBook,
      webBook: webBook ?? this.webBook,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInShelf: isInShelf ?? this.isInShelf,
    );
  }
}

class BookDetailNotifier extends StateNotifier<BookDetailState> {
  final BookRepository _repository;
  final String _bookUrl;

  BookDetailNotifier(this._repository, this._bookUrl)
      : super(BookDetailState()) {
    loadBookDetail();
  }

  Future<void> loadBookDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final localBook = await _repository.getBook(_bookUrl);
      state = state.copyWith(
        localBook: localBook,
        isInShelf: localBook != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addToShelf(WebBook webBook) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final book = Book(
        bookUrl: webBook.bookUrl,
        tocUrl: webBook.tocUrl,
        origin: webBook.origin,
        originName: webBook.originName,
        name: webBook.name,
        author: webBook.author,
        kind: webBook.kind,
        coverUrl: webBook.coverUrl,
        intro: webBook.intro,
        type: 0,
        bookGroup: 0,
        latestChapterTitle: webBook.latestChapterTitle,
        latestChapterTime: DateTime.now().millisecondsSinceEpoch,
        totalChapterNum: webBook.totalChapterNum ?? 0,
        durChapterTitle: null,
        durChapterIndex: 0,
        durChapterPos: 0,
        durChapterTime: 0,
        canUpdate: true,
        order: 0,
        variable: null,
        readConfig: null,
        customTag: null,
        customCoverUrl: null,
      );
      await _repository.saveBook(book);
      state = state.copyWith(
        localBook: book,
        isInShelf: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> removeFromShelf() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteBook(_bookUrl);
      state = state.copyWith(
        localBook: null,
        isInShelf: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
