import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

class MongolParagraph {
  /// To create a [MongolParagraph] object, use a [MongolParagraphBuilder].
  MongolParagraph._(this._paragraphStyle, this._textStyle, this._text);

  ui.ParagraphStyle _paragraphStyle;
  ui.TextStyle _textStyle;
  String _text;

  double _width;
  double _height;
  double _minIntrinsicHeight;
  double _maxIntrinsicHeight;

  List<ui.LineMetrics> _metrics;

  double get width => _width;

  double get height => _height;

  double get minIntrinsicHeight => _minIntrinsicHeight;

  double get maxIntrinsicHeight => _maxIntrinsicHeight;

  void layout(MongolParagraphConstraints constraints) =>
      _layout(constraints.height);

  void _layout(double height) {
    if (height == _height) return;
    _calculateRuns(height);
    _calculateLineBreaks(height);
    _calculateWidth();
    _height = height;
    _calculateIntrinsicHeight();
  }

  List<TextRun> _runs = [];

  void _calculateRuns(double width) {
    if (_runs.isNotEmpty) return;

//    final textSpan = TextSpan(
//      text: _text
//    );
//
//    final textPainter = TextPainter(
//      text: textSpan,
//      textDirection: TextDirection.ltr,
//    );
//    textPainter.layout(
//      minWidth: 0,
//      maxWidth: width,
//    );
//
//    _metrics = textPainter.computeLineMetrics();

    final builder = ui.ParagraphBuilder(_paragraphStyle)
      ..pushStyle(_textStyle)
      ..addText(_text);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: width));

    _metrics = paragraph.computeLineMetrics();
    // print(metrics.length);
    for (ui.LineMetrics m in _metrics) {
      var startPosition = paragraph.getPositionForOffset(Offset(m.left, m.baseline));
      var endPosition = paragraph.getPositionForOffset(Offset(m.left + m.width, m.baseline));
      var lineText = _text.substring(startPosition.offset, endPosition.offset);
      print('line: ${m.lineNumber} => \'$lineText\'');

      var lineBuilder = ui.ParagraphBuilder(_paragraphStyle)
        ..pushStyle(_textStyle)
        ..addText(lineText);
      var line = lineBuilder.build();
      line.layout(ui.ParagraphConstraints(width: double.infinity));
      var run2 = TextRun(startPosition.offset, endPosition.offset, line);
      _runs.add(run2);
    }
  }

  List<LineInfo> _lines = [];

  // Internally this method uses "width" and "height" naming with regard
  // to a horizontal line of text. Rotation doesn't happen until drawing.
  void _calculateLineBreaks(double maxLineLength) {
    assert(_runs != null);
    if (_runs.isEmpty) {
      return;
    }
    if (_lines.isNotEmpty) {
      _lines.clear();
    }

    // add run lengths until exceeds height
    int start = 0;
    int end;
    double lineWidth = 0;
    double lineHeight = 0;
    for (int i = 0; i < _runs.length; i++) {
      end = i;
      final run = _runs[i];
      final runWidth = run.paragraph.maxIntrinsicWidth;
      final runHeight = run.paragraph.height;

      if (lineWidth + runWidth > maxLineLength) {
        _addLine(start, end, lineWidth, lineHeight);
        start = end;
        lineWidth = runWidth;
        lineHeight = runHeight;
      } else {
        lineWidth += runWidth;
        lineHeight = math.max(lineHeight, run.paragraph.height);
      }
    }

    end = _runs.length;
    if (start < end) {
      _addLine(start, end, lineWidth, lineHeight);
    }
  }

  void _addLine(int start, int end, double width, double height) {
    final bounds = Rect.fromLTRB(0, 0, width, height);
    final LineInfo lineInfo = LineInfo(start, end, bounds);
    _lines.add(lineInfo);
  }

  void _calculateWidth() {
    assert(_lines != null);
    assert(_runs != null);
    double sum = 0;
    for (LineInfo line in _lines) {
      sum += line.bounds.height;
    }
    _width = sum;
  }

  // Internally this translates a horizontal run width to the vertical name
  // that it is known as externally.
  // FIXME: This does not handle newline characters.
  void _calculateIntrinsicHeight() {
    assert(_runs != null);

    double sum = 0;
    double maxRunWidth = 0;
    double maxLineLength = 0;
    for (LineInfo line in _lines) {
      for (int i = line.textRunStart; i < line.textRunEnd; i++) {
        final width = _runs[i].paragraph.maxIntrinsicWidth;
        maxRunWidth = math.max(width, maxRunWidth);
        sum += width;
      }
      maxLineLength = math.max(maxLineLength, sum);
      sum = 0;
    }
    _minIntrinsicHeight = maxRunWidth;
    _maxIntrinsicHeight = maxLineLength;
  }

  void draw(Canvas canvas, Offset offset) {
    assert(_lines != null);
    assert(_runs != null);

    // translate for the offset
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // rotate the canvas 90 degrees
    canvas.rotate(math.pi / 2);

    // loop through every line
    for (LineInfo line in _lines) {
      // translate for the line height
      canvas.translate(0, -line.bounds.height);

      // draw each run in the current line
      double dx = 0;
      for (int i = line.textRunStart; i < line.textRunEnd; i++) {
        canvas.drawParagraph(_runs[i].paragraph, Offset(dx, 0));
        dx += _runs[i].paragraph.longestLine;
      }
    }

    canvas.restore();
  }
}

class MongolParagraphConstraints {
  const MongolParagraphConstraints({
    this.height,
  }) : assert(height != null);

  final double height;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final MongolParagraphConstraints typedOther = other;
    return typedOther.height == height;
  }

  @override
  int get hashCode => height.hashCode;

  @override
  String toString() => '$runtimeType(height: $height)';
}

class MongolParagraphBuilder {
  MongolParagraphBuilder(ui.ParagraphStyle style) {
    _paragraphStyle = style;
  }

  ui.ParagraphStyle _paragraphStyle;
  ui.TextStyle _textStyle;
  String _text = '';

  static final _defaultParagraphStyle = ui.ParagraphStyle(
    textAlign: TextAlign.start,
    textDirection: TextDirection.ltr,
    fontSize: 30,
    //fontFamily: MongolFont.qagan,
  );
  static final _defaultTextStyle = ui.TextStyle(
    color: Color(0xFF000000),
    textBaseline: TextBaseline.alphabetic,
    fontSize: 30,
  );

  // The current implementation replaces the old style.
  // TODO: create a stack of styles to push and pop
  void pushStyle(TextStyle style) {
    _textStyle = style.getTextStyle();
  }

  // The current implementation does nothing.
  // TODO: remove the last style from a stack of styles.
  void pop() {}

  // The current implementation does appends the text.
  // TODO: associate the added text with a style.
  void addText(String text) {
    _text += text;
  }

  MongolParagraph build() {
    assert(_text != null);
    if (_paragraphStyle == null) {
      _paragraphStyle = _defaultParagraphStyle;
    }
    if (_textStyle == null) {
      _textStyle = _defaultTextStyle;
    }

    return MongolParagraph._(_paragraphStyle, _textStyle, _text);
  }
}

class LineBreaker {
  String _text;
  List<int> _breaks;

  set text(String text) {
    if (text == _text) {
      return;
    }
    _text = text;
    _breaks = null;
  }

  // returns the number of breaks
  int computeBreaks() {
    assert(_text != null);

    if (_breaks != null) {
      return _breaks.length;
    }
    _breaks = [];

    for (int i = 1; i < _text.length; i++) {
      if (_text[i - 1] == '\n') {
        _breaks.add(i);
      } else if (isBreakChar(_text[i - 1]) && !isBreakChar(_text[i])) {
        _breaks.add(i);
      }
    }

    return _breaks.length;
  }

  List<int> get breaks => _breaks;

  bool isBreakChar(String codeUnit) {
    return codeUnit == ' ';
  }
}

class TextRun {
  TextRun(this.start, this.end, this.paragraph);

  int start;
  int end;
  ui.Paragraph paragraph;
}

class LineInfo {
  LineInfo(this.textRunStart, this.textRunEnd, this.bounds);

  int textRunStart;
  int textRunEnd;
  Rect bounds;
}
