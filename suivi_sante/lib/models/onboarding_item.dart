import 'package:flutter/material.dart';

class OnboardingItem {
  final String title;
  final String description;
  final String image;
  final Color color;
  final IconData icon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
    required this.icon,
  });
}