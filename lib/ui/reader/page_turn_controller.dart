import 'package:flutter/material.dart';

enum PageTurnMode {
  cover,
  simulation,
  slide,
  scroll,
  none,
}

abstract class PageTurnController {
  Widget buildPageView({
    required int pageCount,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
  });

  factory PageTurnController.fromMode(PageTurnMode mode) {
    switch (mode) {
      case PageTurnMode.cover:
        return CoverPageTurnController();
      case PageTurnMode.simulation:
        return SimulationPageTurnController();
      case PageTurnMode.slide:
        return SlidePageTurnController();
      case PageTurnMode.scroll:
        return ScrollPageTurnController();
      case PageTurnMode.none:
        return NonePageTurnController();
    }
  }
}

class CoverPageTurnController implements PageTurnController {
  @override
  Widget buildPageView({
    required int pageCount,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return PageView.builder(
      controller: PageController(initialPage: currentPage),
      itemCount: pageCount,
      onPageChanged: onPageChanged,
      itemBuilder: itemBuilder,
    );
  }
}

class SimulationPageTurnController implements PageTurnController {
  @override
  Widget buildPageView({
    required int pageCount,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return PageView.builder(
      controller: PageController(initialPage: currentPage),
      itemCount: pageCount,
      onPageChanged: onPageChanged,
      scrollDirection: Axis.horizontal,
      pageSnapping: true,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: ModalRoute.of(context)!.animation!,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity(),
              alignment: Alignment.centerLeft,
              child: itemBuilder(context, index),
            );
          },
        );
      },
    );
  }
}

class SlidePageTurnController implements PageTurnController {
  @override
  Widget buildPageView({
    required int pageCount,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return PageView.builder(
      controller: PageController(initialPage: currentPage),
      itemCount: pageCount,
      onPageChanged: onPageChanged,
      itemBuilder: itemBuilder,
    );
  }
}

class ScrollPageTurnController implements PageTurnController {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget buildPageView({
    required int pageCount,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: pageCount,
      itemBuilder: itemBuilder,
    );
  }
}

class NonePageTurnController implements PageTurnController {
  @override
  Widget buildPageView({
    required int pageCount,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return IndexedStack(
      index: currentPage,
      children: List.generate(
        pageCount,
        (index) => itemBuilder(context, index),
      ),
    );
  }
}
