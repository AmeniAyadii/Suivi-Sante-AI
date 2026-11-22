import 'package:flutter/material.dart';

/// Widget sécurisé - remplace Expanded quand le parent n'est pas un Flex
class SafeExpanded extends StatelessWidget {
  final Widget child;
  final int flex;

  const SafeExpanded({
    super.key,
    required this.child,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      fit: FlexFit.tight,
      child: child,
    );
  }
}