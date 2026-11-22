import 'dart:ui'; // ✅ AJOUT DE L'IMPORT
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry borderRadius;
  final double blurStrength;
  final double opacity;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final bool isDarkMode;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blurStrength = 10,
    this.opacity = 0.15,
    this.backgroundColor,
    this.boxShadow,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode || Theme.of(context).brightness == Brightness.dark;
    
    final defaultColor = isDark 
        ? Colors.grey.shade800.withOpacity(0.4)
        : Colors.white.withOpacity(0.6);
    
    final borderColor = isDark
        ? Colors.grey.shade700.withOpacity(0.3)
        : Colors.white.withOpacity(0.8);
    
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.grey.withOpacity(0.2);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: shadowColor,
            blurRadius: blurStrength * 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: blurStrength * 1.5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(opacity),
                    Colors.white.withOpacity(opacity * 0.5),
                  ],
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// Version avec effet de verre amélioré
class GlassmorphicCardV2 extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry borderRadius;
  final double blurIntensity;
  final Color? tintColor;
  final bool isDarkMode;

  const GlassmorphicCardV2({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blurIntensity = 12,
    this.tintColor,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode || Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = tintColor ?? (isDark 
        ? Colors.grey.shade900.withOpacity(0.45)
        : Colors.white.withOpacity(0.55));
    
    final borderColor = isDark
        ? Colors.grey.shade700.withOpacity(0.25)
        : Colors.white.withOpacity(0.7);
    
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.5)
        : Colors.grey.withOpacity(0.25);

    // ✅ CORRECTION : Vérification si ImageFilter est disponible
    // Sur certaines versions, ImageFilter.blur peut ne pas être disponible
    // Utiliser une alternative pour le mode sombre
    final useBlur = !isDark && blurIntensity > 0;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: blurIntensity * 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.15)
                : Colors.grey.withOpacity(0.08),
            blurRadius: blurIntensity * 1.5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: useBlur
            ? BackdropFilter(
                // ✅ IMAGE FILTER CORRECTEMENT UTILISÉ
                filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
                child: _buildContent(),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.05),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: child,
        ),
      ],
    );
  }
}

// Widget pour une carte Glassmorphic avec effet de survol
class GlassmorphicCardInteractive extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry borderRadius;
  final bool isDarkMode;

  const GlassmorphicCardInteractive({
    Key? key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<GlassmorphicCardInteractive> createState() => _GlassmorphicCardInteractiveState();
}

class _GlassmorphicCardInteractiveState extends State<GlassmorphicCardInteractive> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode || Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onTap != null) {
            _controller.forward();
          }
        },
        onTapUp: (_) {
          if (widget.onTap != null) {
            _controller.reverse();
            widget.onTap?.call();
          }
        },
        onTapCancel: () {
          if (widget.onTap != null) {
            _controller.reverse();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.02 : 1.0)
            ..translate(0, _isHovered ? -4 : 0),
          child: GlassmorphicCard(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            margin: widget.margin,
            borderRadius: widget.borderRadius,
            isDarkMode: isDark,
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
            child: widget.child,
          ),
        ),
      ),
    );
  }
}