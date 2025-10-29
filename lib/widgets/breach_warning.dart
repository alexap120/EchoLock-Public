import 'package:flutter/material.dart';

void showBreachWarning(BuildContext context, int breachCount, {VoidCallback? onGenerateNew}) {
  showModalBottomSheet(
    context: context,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[100]!, Colors.orange[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.warning_amber_rounded, size: 86, color: Colors.orange),
              ),
              Text(
                'This password has been breached $breachCount times!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'We recommend you generate a new one.',
                style: TextStyle(fontSize: 16, color: Colors.orange[800]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 42),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        elevation: 0,
                      ),
                      child: const Text('Dismiss', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  if (onGenerateNew != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onGenerateNew();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[900],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          elevation: 0,
                        ),
                        child: const Text('Generate New', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}