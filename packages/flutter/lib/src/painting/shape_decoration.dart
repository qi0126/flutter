// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'borders.dart';
import 'box_border.dart';
import 'box_decoration.dart';
import 'box_shadow.dart';
import 'circle_border.dart';
import 'colors.dart';
import 'decoration.dart';
import 'decoration_image.dart';
import 'edge_insets.dart';
import 'gradient.dart';
import 'image_provider.dart';
import 'rounded_rectangle_border.dart';

/// An immutable description of how to paint an arbitrary shape.
///
/// The [ShapeDecoration] class provides a way to draw a [ShapeBorder],
/// optionally filling it with a color or a gradient, optionally painting an
/// image into it, and optionally casting a shadow.
///
/// {@tool snippet}
///
/// The following example uses the [Container] widget from the widgets layer to
/// draw a white rectangle with a 24-pixel multicolor outline, with the text
/// "RGB" inside it:
///
/// ```dart
/// Container(
///   decoration: ShapeDecoration(
///     color: Colors.white,
///     shape: Border.all(
///       color: Colors.red,
///       width: 8.0,
///     ) + Border.all(
///       color: Colors.green,
///       width: 8.0,
///     ) + Border.all(
///       color: Colors.blue,
///       width: 8.0,
///     ),
///   ),
///   child: const Text('RGB', textAlign: TextAlign.center),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [DecoratedBox] and [Container], widgets that can be configured with
///    [ShapeDecoration] objects.
///  * [BoxDecoration], a similar [Decoration] that is optimized for rectangles
///    specifically.
///  * [ShapeBorder], the base class for the objects that are used in the
///    [shape] property.
class ShapeDecoration extends Decoration {
  /// Creates a shape decoration.
  ///
  /// * If [color] is null, this decoration does not paint a background color.
  /// * If [gradient] is null, this decoration does not paint gradients.
  /// * If [image] is null, this decoration does not paint a background image.
  /// * If [shadows] is null, this decoration does not paint a shadow.
  ///
  /// The [color] and [gradient] properties are mutually exclusive, one (or
  /// both) of them must be null.
  ///
  /// The [shape] must not be null.
  const ShapeDecoration({
    this.color,
    this.image,
    this.gradient,
    this.shadows,
    required this.shape,
  }) : assert(!(color != null && gradient != null)),
       assert(shape != null);

  /// Creates a shape decoration configured to match a [BoxDecoration].
  ///
  /// The [BoxDecoration] class is more efficient for shapes that it can
  /// describe than the [ShapeDecoration] class is for those same shapes,
  /// because [ShapeDecoration] has to be more general as it can support any
  /// shape. However, having a [ShapeDecoration] is sometimes necessary, for
  /// example when calling [ShapeDecoration.lerp] to transition between
  /// different shapes (e.g. from a [CircleBorder] to a
  /// [RoundedRectangleBorder]; the [BoxDecoration] class cannot animate the
  /// transition from a [BoxShape.circle] to [BoxShape.rectangle]).
  factory ShapeDecoration.fromBoxDecoration(BoxDecoration source) {
    ShapeBorder shape;
    assert(source.shape != null);
    switch (source.shape) {
      case BoxShape.circle:
        if (source.border != null) {
          assert(source.border!.isUniform);
          shape = CircleBorder(side: source.border!.top);
        } else {
          shape = const CircleBorder();
        }
        break;
      case BoxShape.rectangle:
        if (source.borderRadius != null) {
          assert(source.border == null || source.border!.isUniform);
          shape = RoundedRectangleBorder(
            side: source.border?.top ?? BorderSide.none,
            borderRadius: source.borderRadius!,
          );
        } else {
          shape = source.border ?? const Border();
        }
        break;
    }
    return ShapeDecoration(
      color: source.color,
      image: source.image,
      gradient: source.gradient,
      shadows: source.boxShadow,
      shape: shape,
    );
  }

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) {
    return shape.getOuterPath(rect, textDirection: textDirection);
  }

  /// The color to fill in the background of the shape.
  ///
  /// The color is under the [image].
  ///
  /// If a [gradient] is specified, [color] must be null.
  final Color? color;

  /// A gradient to use when filling the shape.
  ///
  /// The gradient is under the [image].
  ///
  /// If a [color] is specified, [gradient] must be null.
  final Gradient? gradient;

  /// An image to paint inside the shape (clipped to its outline).
  ///
  /// The image is drawn over the [color] or [gradient].
  final DecorationImage? image;

  /// A list of shadows cast by the [shape].
  ///
  /// See also:
  ///
  ///  * [kElevationToShadow], for some predefined shadows used in Material
  ///    Design.
  ///  * [PhysicalModel], a widget for showing shadows.
  final List<BoxShadow>? shadows;

  /// The shape to fill the [color], [gradient], and [image] into and to cast as
  /// the [shadows].
  ///
  /// Shapes can be stacked (using the `+` operator). The color, gradient, and
  /// image are drawn into the inner-most shape specified.
  ///
  /// The [shape] property specifies the outline (border) of the decoration. The
  /// shape must not be null.
  ///
  /// ## Directionality-dependent shapes
  ///
  /// Some [ShapeBorder] subclasses are sensitive to the [TextDirection]. The
  /// direction that is provided to the border (e.g. for its [ShapeBorder.paint]
  /// method) is the one specified in the [ImageConfiguration]
  /// ([ImageConfiguration.textDirection]) provided to the [BoxPainter] (via its
  /// [BoxPainter.paint method). The [BoxPainter] is obtained when
  /// [createBoxPainter] is called.
  ///
  /// When a [ShapeDecoration] is used with a [Container] widget or a
  /// [DecoratedBox] widget (which is what [Container] uses), the
  /// [TextDirection] specified in the [ImageConfiguration] is obtained from the
  /// ambient [Directionality], using [createLocalImageConfiguration].
  final ShapeBorder shape;

  /// The inset space occupied by the [shape]'s border.
  ///
  /// This value may be misleading. See the discussion at [ShapeBorder.dimensions].
  @override
  EdgeInsetsGeometry get padding => shape.dimensions;

  @override
  bool get isComplex => shadows != null;

  @override
  ShapeDecoration? lerpFrom(Decoration? a, double t) {
    if (a is BoxDecoration) {
      return ShapeDecoration.lerp(ShapeDecoration.fromBoxDecoration(a), this, t);
    } else if (a == null || a is ShapeDecoration) {
      return ShapeDecoration.lerp(a as ShapeDecoration, this, t);
    }
    return super.lerpFrom(a, t) as ShapeDecoration?;
  }

  @override
  ShapeDecoration? lerpTo(Decoration? b, double t) {
    if (b is BoxDecoration) {
      return ShapeDecoration.lerp(this, ShapeDecoration.fromBoxDecoration(b), t);
    } else if (b == null || b is ShapeDecoration) {
      return ShapeDecoration.lerp(this, b as ShapeDecoration, t);
    }
    return super.lerpTo(b, t) as ShapeDecoration?;
  }

  /// Linearly interpolate between two shapes.
  ///
  /// Interpolates each parameter of the decoration separately.
  ///
  /// If both values are null, this returns null. Otherwise, it returns a
  /// non-null value, with null arguments treated like a [ShapeDecoration] whose
  /// fields are all null (including the [shape], which cannot normally be
  /// null).
  ///
  /// {@macro dart.ui.shadow.lerp}
  ///
  /// See also:
  ///
  ///  * [Decoration.lerp], which can interpolate between any two types of
  ///    [Decoration]s, not just [ShapeDecoration]s.
  ///  * [lerpFrom] and [lerpTo], which are used to implement [Decoration.lerp]
  ///    and which use [ShapeDecoration.lerp] when interpolating two
  ///    [ShapeDecoration]s or a [ShapeDecoration] to or from null.
  static ShapeDecoration? lerp(ShapeDecoration? a, ShapeDecoration? b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    if (a != null && b != null) {
      if (t == 0.0)
        return a;
      if (t == 1.0)
        return b;
    }
    return ShapeDecoration(
      color: Color.lerp(a?.color, b?.color, t),
      gradient: Gradient.lerp(a?.gradient, b?.gradient, t),
      image: t < 0.5 ? a!.image : b!.image, // TODO(ianh): cross-fade the image
      shadows: BoxShadow.lerpList(a?.shadows, b?.shadows, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is ShapeDecoration
        && other.color == color
        && other.gradient == gradient
        && other.image == image
        && listEquals<BoxShadow>(other.shadows, shadows)
        && other.shape == shape;
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      gradient,
      image,
      shape,
      hashList(shadows),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace;
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<Gradient>('gradient', gradient, defaultValue: null));
    properties.add(DiagnosticsProperty<DecorationImage>('image', image, defaultValue: null));
    properties.add(IterableProperty<BoxShadow>('shadows', shadows, defaultValue: null, style: DiagnosticsTreeStyle.whitespace));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape));
  }

  @override
  bool hitTest(Size size, Offset position, { TextDirection? textDirection }) {
    return shape.getOuterPath(Offset.zero & size, textDirection: textDirection).contains(position);
  }

  @override
  _ShapeDecorationPainter createBoxPainter([ VoidCallback? onChanged ]) {
    assert(onChanged != null || image == null);
    return _ShapeDecorationPainter(this, onChanged!);
  }
}

/// An object that paints a [ShapeDecoration] into a canvas.
class _ShapeDecorationPainter extends BoxPainter {
  _ShapeDecorationPainter(this._decoration, VoidCallback onChanged)
    : assert(_decoration != null),
      super(onChanged);

  final ShapeDecoration _decoration;

  Rect? _lastRect;
  TextDirection? _lastTextDirection;
  late Path _outerPath;
  Path? _innerPath;
  Paint? _interiorPaint;
  int? _shadowCount;
  late List<Path> _shadowPaths;
  late List<Paint> _shadowPaints;

  @override
  VoidCallback get onChanged => super.onChanged!;

  void _precache(Rect rect, TextDirection? textDirection) {
    assert(rect != null);
    if (rect == _lastRect && textDirection == _lastTextDirection)
      return;

    // We reach here in two cases:
    //  - the very first time we paint, in which case everything except _decoration is null
    //  - subsequent times, if the rect has changed, in which case we only need to update
    //    the features that depend on the actual rect.
    if (_interiorPaint == null && (_decoration.color != null || _decoration.gradient != null)) {
      _interiorPaint = Paint();
      if (_decoration.color != null)
        _interiorPaint!.color = _decoration.color!;
    }
    if (_decoration.gradient != null)
      _interiorPaint!.shader = _decoration.gradient!.createShader(rect);
    if (_decoration.shadows != null) {
      if (_shadowCount == null) {
        _shadowCount = _decoration.shadows!.length;
        _shadowPaints = <Paint>[
          ..._decoration.shadows!.map((BoxShadow shadow) => shadow.toPaint()),
        ];
      }
      _shadowPaths = <Path>[
        ..._decoration.shadows!.map((BoxShadow shadow) {
          return _decoration.shape.getOuterPath(rect.shift(shadow.offset).inflate(shadow.spreadRadius), textDirection: textDirection);
        }),
      ];
    }
    if (_interiorPaint != null || _shadowCount != null)
      _outerPath = _decoration.shape.getOuterPath(rect, textDirection: textDirection);
    if (_decoration.image != null)
      _innerPath = _decoration.shape.getInnerPath(rect, textDirection: textDirection);

    _lastRect = rect;
    _lastTextDirection = textDirection;
  }

  void _paintShadows(Canvas canvas) {
    if (_shadowCount != null) {
      for (int index = 0; index < _shadowCount!; index += 1)
        canvas.drawPath(_shadowPaths[index], _shadowPaints[index]);
    }
  }

  void _paintInterior(Canvas canvas) {
    if (_interiorPaint != null)
      canvas.drawPath(_outerPath, _interiorPaint!);
  }

  DecorationImagePainter? _imagePainter;
  void _paintImage(Canvas canvas, ImageConfiguration configuration) {
    if (_decoration.image == null)
      return;
    _imagePainter ??= _decoration.image!.createPainter(onChanged);
    _imagePainter!.paint(canvas, _lastRect!, _innerPath, configuration);
  }

  @override
  void dispose() {
    _imagePainter?.dispose();
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size!;
    final TextDirection? textDirection = configuration.textDirection;
    _precache(rect, textDirection);
    _paintShadows(canvas);
    _paintInterior(canvas);
    _paintImage(canvas, configuration);
    _decoration.shape.paint(canvas, rect, textDirection: textDirection);
  }
}
