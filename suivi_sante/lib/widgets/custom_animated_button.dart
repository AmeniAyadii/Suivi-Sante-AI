import 'package:flutter/material.dart';

/// Bouton animé personnalisé avec effet de scale et ripple
class CustomAnimatedButton extends StatefulWidget {
  /// Contenu du bouton (généralement un Text ou un Row avec icône)
  final Widget child;
  
  /// Fonction appelée lors du clic
  final VoidCallback? onPressed;
  
  /// Couleur de fond du bouton
  final Color? backgroundColor;
  
  /// Couleur de fond lors du survol/contact
  final Color? highlightColor;
  
  /// Couleur de l'onde de ripple
  final Color? splashColor;
  
  /// Rayon des coins
  final double borderRadius;
  
  /// Hauteur du bouton
  final double? height;
  
  /// Largeur du bouton
  final double? width;
  
  /// Padding interne
  final EdgeInsetsGeometry? padding;
  
  /// Ombre portée
  final List<BoxShadow>? boxShadow;
  
  /// Bordure
  final BoxBorder? border;
  
  /// Gradient de fond
  final Gradient? gradient;
  
  /// Facteur d'échelle au clic (0.95 par défaut)
  final double scaleFactor;
  
  /// Durée de l'animation en millisecondes
  final int animationDuration;

  const CustomAnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.highlightColor,
    this.splashColor,
    this.borderRadius = 12,
    this.height,
    this.width,
    this.padding,
    this.boxShadow,
    this.border,
    this.gradient,
    this.scaleFactor = 0.95,
    this.animationDuration = 150,
  });

  @override
  State<CustomAnimatedButton> createState() => _CustomAnimatedButtonState();
}

class _CustomAnimatedButtonState extends State<CustomAnimatedButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDuration),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.height,
              width: widget.width,
              padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                gradient: widget.gradient,
                color: widget.backgroundColor ?? Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget.border,
                boxShadow: widget.boxShadow ?? [
                  BoxShadow(
                    color: (widget.backgroundColor ?? Theme.of(context).primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bouton animé avec effet de chargement intégré
class CustomLoadingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? loadingColor;
  final double borderRadius;
  final double? height;
  final double? width;
  final IconData? icon;

  const CustomLoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.loadingColor,
    this.borderRadius = 12,
    this.height,
    this.width,
    this.icon,
  });

  @override
  State<CustomLoadingButton> createState() => _CustomLoadingButtonState();
}

class _CustomLoadingButtonState extends State<CustomLoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CustomLoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomAnimatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      backgroundColor: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      height: widget.height,
      width: widget.width,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: widget.isLoading
            ? SizedBox(
                key: const ValueKey('loading'),
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.loadingColor ?? Colors.white,
                  ),
                ),
              )
            : Row(
                key: const ValueKey('content'),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon!, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.text),
                ],
              ),
      ),
    );
  }
}

/// Bouton avec effet d'onde expansif
class CustomExpandingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final double radius;

  const CustomExpandingButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.radius = 30,
  });

  @override
  State<CustomExpandingButton> createState() => _CustomExpandingButtonState();
}

class _CustomExpandingButtonState extends State<CustomExpandingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: widget.radius * 2,
            height: widget.radius * 2,
            decoration: BoxDecoration(
              color: widget.color ?? Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.color ?? Theme.of(context).primaryColor)
                      .withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}