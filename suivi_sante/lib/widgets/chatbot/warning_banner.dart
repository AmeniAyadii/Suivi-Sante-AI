import 'package:flutter/material.dart';


class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.amber.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: Color(0xFF7A6B3A),
                ),
                children: const [
                  TextSpan(
                    text: '⚠️ Ne remplace pas un avis médical. ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'En cas d\'urgence, contactez le 15 ou un professionnel de santé.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
