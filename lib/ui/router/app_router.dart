import 'package:flutter/material.dart';
import '../../constants/strings.dart';
import '../../data/database/daos/book_dao.dart' show Book;
import '../bookshelf/bookshelf_screen.dart';
import '../reader/reader_screen.dart';
import '../search/search_screen.dart';
import '../search/book_detail_screen.dart';
import '../explore/explore_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/about_screen.dart';
import '../book_source/book_source_list_screen.dart';
import '../book_source/book_source_edit_screen.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.bookshelf:
        return MaterialPageRoute(
          builder: (_) => const BookshelfScreen(),
          settings: settings,
        );
      case AppRoutes.reader:
        final args = settings.arguments as Map<String, dynamic>?;
        final book = args?['book'] as Book?;
        final initialChapter = args?['initialChapter'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => ReaderScreen(
            book: book!,
            initialChapterIndex: initialChapter,
          ),
          settings: settings,
        );
      case AppRoutes.search:
        return MaterialPageRoute(
          builder: (_) => const SearchScreen(),
          settings: settings,
        );
      case AppRoutes.bookDetail:
        return MaterialPageRoute(
          builder: (_) => const BookDetailScreen(),
          settings: settings,
        );
      case AppRoutes.explore:
        return MaterialPageRoute(
          builder: (_) => const ExploreScreen(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case AppRoutes.about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
          settings: settings,
        );
      case AppRoutes.bookSource:
        return MaterialPageRoute(
          builder: (_) => const BookSourceListScreen(),
          settings: settings,
        );
      case AppRoutes.bookSourceEdit:
        return MaterialPageRoute(
          builder: (_) => const BookSourceEditScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const BookshelfScreen(),
          settings: settings,
        );
    }
  }
}
