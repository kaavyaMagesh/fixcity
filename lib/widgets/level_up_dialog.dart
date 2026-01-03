import 'package:flutter/material.dart';

class LevelUpDialog extends StatefulWidget {
  final int points;
  final String severity;

  const LevelUpDialog({
    super.key,
    required this.points,
    required this.severity,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF6D00), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6D00).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🏆 TROPHY ICON
              const Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: Color(0xFFFFD700),
              ), // Gold
              const SizedBox(height: 20),

              // 🎉 TITLE
              const Text(
                "REPORT SUBMITTED!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),

              // ✨ XP EARNED
              Text(
                "+${widget.points} XP",
                style: const TextStyle(
                  color: Color(0xFFFF6D00),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.orange, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 10),

              Text(
                "Severity: ${widget.severity}",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              // 🔘 BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Go back to Home
                },
                child: const Text("CLAIM REWARD"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
