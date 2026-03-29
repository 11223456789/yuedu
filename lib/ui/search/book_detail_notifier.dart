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
  final SearchBook? searchBook;
  final bool isLoading;
  final String? error;
  final bool isInShelf;

  BookDetailState({
    this.localBook,
    this.searchBook,
    this.isLoading = false,
    this.error,
    this.isInShelf = false,
  });

  BookDetailState copyWith({
    Book? localBook,
    SearchBook? searchBook,
    bool? isLoading,
    String? error,
    bool? isInShelf,
  }) {
    return BookDetailState(
      localBook: localBook ?? this.localBook,
      searchBook: searchBook ?? this.searchBook,
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

  Future<void> addToShelf(SearchBook searchBook) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final book = Book(
        bookUrl: searchBook.bookUrl,
        tocUrl: '',
        origin: searchBook.origin ?? '',
        originName: searchBook.origin ?? '',
        name: searchBook.name,
        author: searchBook.author,
        kind: searchBook.kind,
        coverUrl: searchBook.coverUrl,
        intro: searchBook.intro,
        type: 0,
        bookGroup: 0,
        latestChapterTitle: searchBook.lastChapter,
        latestChapterTime: DateTime.now().millisecondsSinceEpoch,
        totalChapterNum: 0,
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
