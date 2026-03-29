import 'package:flutter/material.dart';

class PageContent {
  final String text;
  final int startOffset;
  final int endOffset;

  PageContent({
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });
}

class PageSplitter {
  final String text;
  final TextStyle textStyle;
  final double pageWidth;
  final double pageHeight;
  final EdgeInsets padding;

  PageSplitter({
    required this.text,
    required this.textStyle,
    required this.pageWidth,
    required this.pageHeight,
    this.padding = const EdgeInsets.all(16),
  });

  List<PageContent> split() {
    final List<PageContent> pages = [];
    final availableWidth = pageWidth - padding.left - padding.right;
    final availableHeight = pageHeight - padding.top - padding.bottom;

    if (text.isEmpty) {
      return pages;
    }

    int currentOffset = 0;
    final paragraphs = _splitParagraphs(text);

    for (final paragraph in paragraphs) {
      if (currentOffset >= text.length) break;

      final paragraphStart = text.indexOf(paragraph, currentOffset);
      final paragraphEnd = paragraphStart + paragraph.length;

      final textSpan = TextSpan(text: paragraph, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      textPainter.layout(maxWidth: availableWidth);
      final lineHeight = textPainter.preferredLineHeight;
      final linesPerPage = (availableHeight / lineHeight).floor();

      if (linesPerPage <= 0) continue;

      final words = _splitWords(paragraph);
      String currentPageText = '';
      int currentLineCount = 0;
      int wordIndex = 0;

      while (wordIndex < words.length) {
        final testText = currentPageText.isEmpty
            ? words[wordIndex]
            : '$currentPageText ${words[wordIndex]}';

        final testSpan = TextSpan(text: testText, style: textStyle);
        final testPainter = TextPainter(
          text: testSpan,
          textDirection: TextDirection.ltr,
          maxLines: null,
        );

        testPainter.layout(maxWidth: availableWidth);
        final testLineCount = _calculateLineCount(testPainter, availableWidth);

        if (testLineCount > linesPerPage) {
          if (currentPageText.isNotEmpty) {
            final pageStart = text.indexOf(currentPageText, paragraphStart);
            final pageEnd = pageStart + currentPageText.length;
            pages.add(PageContent(
              text: currentPageText,
              startOffset: pageStart,
              endOffset: pageEnd,
            ));
            currentOffset = pageEnd;
            currentPageText = '';
            currentLineCount = 0;
          } else {
            final pageStart = text.indexOf(words[wordIndex], paragraphStart);
            final pageEnd = pageStart + words[wordIndex].length;
            pages.add(PageContent(
              text: words[wordIndex],
              startOffset: pageStart,
              endOffset: pageEnd,
            ));
            currentOffset = pageEnd;
            wordIndex++;
          }
        } else {
          currentPageText = testText;
          currentLineCount = testLineCount;
          wordIndex++;
        }
      }

      if (currentPageText.isNotEmpty) {
        final pageStart = text.indexOf(currentPageText, paragraphStart);
        final pageEnd = pageStart + currentPageText.length;
        pages.add(PageContent(
          text: currentPageText,
          startOffset: pageStart,
          endOffset: pageEnd,
        ));
        currentOffset = pageEnd;
      }
    }

    return pages;
  }

  List<String> _splitParagraphs(String text) {
    return text.split(RegExp(r'\n\s*\n'));
  }

  List<String> _splitWords(String text) {
    final words = <String>[];
    final buffer = StringBuffer();
    bool inChinese = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isChineseChar = _isChinese(char);

      if (isChineseChar != inChinese && buffer.isNotEmpty) {
        words.add(buffer.toString());
        buffer.clear();
      }

      inChinese = isChineseChar;

      if (isChineseChar) {
        words.add(char);
      } else if (char == ' ' || char == '\n') {
        if (buffer.isNotEmpty) {
          words.add(buffer.toString());
          buffer.clear();
        }
        if (char == '\n') {
          words.add('\n');
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      words.add(buffer.toString());
    }

    return words;
  }

  bool _isChinese(String char) {
    final codeUnit = char.codeUnitAt(0);
    return (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
        (codeUnit >= 0x3400 && codeUnit <= 0x4DBF) ||
        (codeUnit >= 0x20000 && codeUnit <= 0x2A6DF) ||
        (codeUnit >= 0x2A700 && codeUnit <= 0x2B73F) ||
        (codeUnit >= 0x2B740 && codeUnit <= 0x2B81F) ||
        (codeUnit >= 0x2B820 && codeUnit <= 0x2CEAF) ||
        (codeUnit >= 0xF900 && codeUnit <= 0xFAFF) ||
        (codeUnit >= 0x2F800 && codeUnit <= 0x2FA1F);
  }

  int _calculateLineCount(TextPainter painter, double maxWidth) {
    int lineCount = 0;
    final metrics = painter.computeLineMetrics();
    return metrics.length;
  }
}
