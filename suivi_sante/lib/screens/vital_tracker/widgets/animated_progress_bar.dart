import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatefulWidget {
  final double value; // 0.0 à 1.0
  final double height;
  final double width;
  final Color? color;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BorderRadiusGeometry borderRadius;
  final Duration animationDuration;
  final Curve curve;
  final bool showPercentage;
  final TextStyle? percentageTextStyle;
  final String? label;
  final TextStyle? labelStyle;
  final double labelSpacing;
  final bool animateOnInit;
  final Widget? trailing;

  const AnimatedProgressBar({
    Key? key,
    required this.value,
    this.height = 8,
    this.width = double.infinity,
    this.color,
    this.backgroundColor,
    this.gradient,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.animationDuration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.showPercentage = false,
    this.percentageTextStyle,
    this.label,
    this.labelStyle,
    this.labelSpacing = 8,
    this.animateOnInit = true,
    this.trailing,
  }) : super(key: key);

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentValue = 0.0;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    if (widget.animateOnInit) {
      _controller.forward();
    }

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _animation.addListener(() {
      setState(() {
        _currentValue = _animation.value;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.animateOnInit) {
        _controller.forward(from: 0.0);
      } else {
        setState(() {
          _currentValue = widget.value.clamp(0.0, 1.0);
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _currentValue,
        end: widget.value.clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final defaultColor = widget.color ?? Colors.blue.shade600;
    final defaultBackgroundColor = widget.backgroundColor ?? 
        (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final defaultPercentageTextStyle = widget.percentageTextStyle ??
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: defaultColor,
        );

    // Builder pour le contenu de la barre
    Widget progressBar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null || widget.trailing != null)
          Padding(
            padding: EdgeInsets.only(bottom: widget.labelSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: widget.labelStyle ??
                        TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                  ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: defaultBackgroundColor,
            borderRadius: widget.borderRadius,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: FractionallySizedBox(
              widthFactor: _currentValue,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.gradient != null ? null : defaultColor,
                  gradient: widget.gradient,
                ),
                child: widget.showPercentage
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.height > 16 ? 8 : 4,
                          ),
                          child: Text(
                            '${(_currentValue * 100).round()}%',
                            style: widget.percentageTextStyle ??
                                TextStyle(
                                  fontSize: widget.height > 20 ? 12 : 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );

    // Si on affiche le pourcentage en dehors
    if (widget.showPercentage) {
      return Stack(
        children: [
          progressBar,
          Positioned(
            right: 0,
            top: widget.label != null ? -4 : 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: defaultColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(widget.value * 100).round()}%',
                style: defaultPercentageTextStyle,
              ),
            ),
          ),
        ],
      );
    }

    return progressBar;
  }
}

// Version avec effet de gradient animé
class AnimatedGradientProgressBar extends StatefulWidget {
  final double value;
  final double height;
  final double width;
  final List<Color> colors;
  final Duration animationDuration;
  final Duration gradientAnimationDuration;
  final bool showPercentage;
  final String? label;
  final TextStyle? labelStyle;
  final VoidCallback? onComplete;

  const AnimatedGradientProgressBar({
    Key? key,
    required this.value,
    this.height = 12,
    this.width = double.infinity,
    this.colors = const [Colors.blue, Colors.purple, Colors.pink],
    this.animationDuration = const Duration(milliseconds: 1000),
    this.gradientAnimationDuration = const Duration(seconds: 3),
    this.showPercentage = false,
    this.label,
    this.labelStyle,
    this.onComplete,
  }) : super(key: key);

  @override
  State<AnimatedGradientProgressBar> createState() => _AnimatedGradientProgressBarState();
}

class _AnimatedGradientProgressBarState extends State<AnimatedGradientProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _gradientController;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Animation de progression
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _progressAnimation.addListener(() {
      setState(() {
        _currentProgress = _progressAnimation.value;
      });
      if (_currentProgress >= 1.0 && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
    
    // Animation du gradient
    _gradientController = AnimationController(
      duration: widget.gradientAnimationDuration,
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController.forward();
  }

  @override
  void didUpdateWidget(AnimatedGradientProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: widget.value.clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeOutCubic,
        ),
      );
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: widget.labelStyle ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
            ),
          ),
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.height / 2),
            child: FractionallySizedBox(
              widthFactor: _currentProgress,
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _gradientController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: widget.colors,
                        stops: [
                          (_gradientController.value * 0.5),
                          (_gradientController.value * 0.5 + 0.3),
                          (_gradientController.value * 0.5 + 0.6),
                        ],
                      ),
                    ),
                    child: widget.showPercentage
                        ? Center(
                            child: Text(
                              '${(widget.value * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget pour une barre de progression circulaire
class AnimatedCircularProgressBar extends StatelessWidget {
  final double value;
  final double radius;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Widget? centerWidget;
  final Duration animationDuration;
  final Curve curve;
  final bool showPercentage;
  final TextStyle? percentageTextStyle;

  const AnimatedCircularProgressBar({
    Key? key,
    required this.value,
    this.radius = 50,
    this.strokeWidth = 8,
    this.color,
    this.backgroundColor,
    this.gradient,
    this.centerWidget,
    this.animationDuration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.showPercentage = false,
    this.percentageTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color defaultColor = color ?? Colors.blue.shade600;
    final Color defaultBackgroundColor = backgroundColor ?? Colors.grey.shade200;
    
    return TweenAnimationBuilder<double>(
      duration: animationDuration,
      curve: curve,
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      builder: (context, progress, child) {
        return SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fond
              CustomPaint(
                painter: CircularProgressPainter(
                  value: 1.0,
                  color: defaultBackgroundColor,
                  strokeWidth: strokeWidth,
                ),
              ),
              // Progression
              CustomPaint(
                painter: CircularProgressPainter(
                  value: progress,
                  color: gradient != null ? null : defaultColor,
                  gradient: gradient,
                  strokeWidth: strokeWidth,
                  startAngle: -90,
                ),
              ),
              // Contenu central
              if (centerWidget != null) centerWidget!,
              if (showPercentage && centerWidget == null)
                Text(
                  '${(progress * 100).round()}%',
                  style: percentageTextStyle ??
                      TextStyle(
                        fontSize: radius * 0.3,
                        fontWeight: FontWeight.bold,
                        color: defaultColor,
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Painter pour la barre circulaire
class CircularProgressPainter extends CustomPainter {
  final double value;
  final Color? color;
  final Gradient? gradient;
  final double strokeWidth;
  final double startAngle;

  CircularProgressPainter({
    required this.value,
    this.color,
    this.gradient,
    this.strokeWidth = 8,
    this.startAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final sweepAngle = value * 360;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      paint.shader = gradient!.createShader(rect);
    } else if (color != null) {
      paint.color = color!;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle * 3.14159 / 180,
      sweepAngle * 3.14159 / 180,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.color != color ||
           oldDelegate.gradient != gradient ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}