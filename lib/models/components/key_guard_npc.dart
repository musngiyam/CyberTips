import 'package:flutter/material.dart';
import 'dart:math';

class KeyGuardNPC extends StatelessWidget {
  final bool hasKeyObtained;
  final VoidCallback onKeyAcquired;
  final VoidCallback? onProceed;

  const KeyGuardNPC({
    super.key,
    required this.hasKeyObtained,
    required this.onKeyAcquired,
    this.onProceed,
  });

  static void showKeyGuardDialog({
    required BuildContext context,
    required bool hasKeyObtained,
    required VoidCallback onKeyAcquired,
    VoidCallback? onProceed,
  }) {
    final Random random = Random();

    final List<Map<String, String>> quests = [
      {'number': '1', 'name': 'Flipping Card'},
      {'number': '2', 'name': 'Caesar Cipher'},
      {'number': '3', 'name': 'Missing Letter'},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Randomized question state variables inside builder
          var selectedQuest = quests[random.nextInt(quests.length)];
          String targetQuestNum = selectedQuest['number']!;
          String correctChoice = selectedQuest['name']!;

          List<String> choices = ['Flipping Card', 'Caesar Cipher', 'Missing Letter'];
          choices.shuffle(random);

          String dialogMessage = hasKeyObtained
              ? "You have already obtained the key!"
              : "I hold the key you seek! Answer me truly: What is Quest $targetQuestNum all about?";
          bool showingFeedback = false;
          bool isCorrectAnswer = false;

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E281A).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF8FBC8F), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: StatefulBuilder(
                  builder: (innerContext, setInnerState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Gatekeeper of the Key",
                          style: TextStyle(
                            color: Color(0xFFE8F5E9),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A11),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF324C2C), width: 1),
                          ),
                          child: Text(
                            dialogMessage,
                            style: const TextStyle(
                              color: Color(0xFFCFD8DC),
                              fontSize: 11,
                              height: 1.3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!hasKeyObtained) ...[
                          if (!showingFeedback) ...[
                            ...choices.map((choice) => _buildChoiceButton(
                              label: choice,
                              onTap: () {
                                setInnerState(() {
                                  showingFeedback = true;
                                  if (choice == correctChoice) {
                                    isCorrectAnswer = true;
                                    dialogMessage = "Correct! You answered right. Here is your key!";
                                  } else {
                                    isCorrectAnswer = false;
                                    dialogMessage = "Incorrect! That is not correct. No key for you!";
                                  }
                                });
                              },
                            )),
                          ] else ...[
                            if (isCorrectAnswer)
                              _buildChoiceButton(
                                label: "Claim Key",
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  onKeyAcquired();
                                },
                              )
                            else
                              _buildChoiceButton(
                                label: "Try Again",
                                onTap: () {
                                  setInnerState(() {
                                    // Re-roll a new random question on retry
                                    selectedQuest = quests[random.nextInt(quests.length)];
                                    targetQuestNum = selectedQuest['number']!;
                                    correctChoice = selectedQuest['name']!;
                                    choices.shuffle(random);

                                    showingFeedback = false;
                                    dialogMessage = "I hold the key you seek! Answer me truly: What is Quest $targetQuestNum all about?";
                                  });
                                },
                              ),
                          ],
                        ] else ...[
                          _buildChoiceButton(
                            label: "Proceed through Gate",
                            onTap: () {
                              Navigator.pop(dialogContext);
                              if (onProceed != null) onProceed();
                            },
                          ),
                        ],
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                color: Color(0xFFFFF9C4),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildChoiceButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF263322),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFF558B2F), width: 1),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF81C784),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showKeyGuardDialog(
        context: context,
        hasKeyObtained: hasKeyObtained,
        onKeyAcquired: onKeyAcquired,
        onProceed: onProceed,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white38, width: 2),
        ),
        child: const Text(
          "Talk",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}