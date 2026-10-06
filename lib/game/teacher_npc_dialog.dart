import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../current_user.dart';
import '../teacher_quiz_service.dart';
import 'teacher_battle_screen.dart';

class TeacherNpcDialog extends StatefulWidget {
  final int characterIndex;
  final Function(TeacherQuizModel quiz)? onStartBattle;

  const TeacherNpcDialog({
    super.key,
    required this.characterIndex,
    this.onStartBattle,
  });

  @override
  State<TeacherNpcDialog> createState() => _TeacherNpcDialogState();
}

class _TeacherNpcDialogState extends State<TeacherNpcDialog> {
  int _selectedTabIndex = 0; // 0: Generate, 1: Enter, 2: Scores

  // Teacher Authentication
  bool _isTeacherAuthenticated = false;
  bool _obscurePassword = true;
  final TextEditingController _passwordController = TextEditingController();
  String? _authError;

  // Generate Tab Form Controllers
  String _selectedGameType = 'missing_letter'; // 'missing_letter' or 'caesar_matrix'
  String _selectedDifficulty = 'medium'; // 'easy', 'medium', 'hard'

  // 3 Questions / Words Controllers
  final List<TextEditingController> _definitionControllers = [
    TextEditingController(text: "A security system monitoring network traffic."),
    TextEditingController(text: "Converting plaintext into unreadable ciphertext."),
    TextEditingController(text: "Secret passphrase used for authentication."),
  ];

  final List<TextEditingController> _wordControllers = [
    TextEditingController(text: "FIREWALL"),
    TextEditingController(text: "ENCRYPT"),
    TextEditingController(text: "PASSWORD"),
  ];

  int _selectedMissingCount = 2;
  String? _generatedCodeKey;
  bool _isGenerating = false;

  // Enter Tab Controllers
  final TextEditingController _enterCodeController = TextEditingController();
  TeacherQuizModel? _loadedQuiz;
  bool _isSearchingQuiz = false;
  bool _hasAlreadyAttempted = false;
  String? _enterQuizError;

  // Scores Tab Controllers
  final TextEditingController _scoresCodeController = TextEditingController();
  List<TeacherScoreEntry>? _loadedScores;
  bool _isLoadingScores = false;
  String? _scoresError;

  @override
  void dispose() {
    _passwordController.dispose();
    for (var c in _definitionControllers) {
      c.dispose();
    }
    for (var c in _wordControllers) {
      c.dispose();
    }
    _enterCodeController.dispose();
    _scoresCodeController.dispose();
    super.dispose();
  }

  void _verifyPassword() {
    setState(() {
      _authError = null;
    });

    if (_passwordController.text.trim() == "hcc12345") {
      setState(() {
        _isTeacherAuthenticated = true;
      });
    } else {
      setState(() {
        _authError = "Incorrect password! Access denied.";
      });
    }
  }

  int _calculateMaxAllowedMissing() {
    int minLength = 99;
    for (var controller in _wordControllers) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        minLength = min(minLength, text.length);
      }
    }
    if (minLength == 99) return 2;
    final maxAllowed = max(1, minLength - 1);
    return min(maxAllowed, 3);
  }

  void _handleGenerateQuiz() async {
    List<TeacherQuestionItem> questions = [];
    for (int i = 0; i < 3; i++) {
      final def = _definitionControllers[i].text.trim();
      final word = _wordControllers[i].text.trim().toUpperCase();

      if (word.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please enter a valid word for Question ${i + 1}."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (word.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Word ${i + 1} ('$word') must be at least 2 letters long."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      questions.add(TeacherQuestionItem(
        definition: def.isNotEmpty ? def : "Cybersecurity Trial ${i + 1}",
        word: word,
      ));
    }

    final maxMissing = _calculateMaxAllowedMissing();
    final effectiveMissing = min(_selectedMissingCount, maxMissing);

    setState(() {
      _isGenerating = true;
      _generatedCodeKey = null;
    });

    final code = await TeacherQuizService().createQuiz(
      gameType: _selectedGameType,
      difficulty: _selectedDifficulty,
      questions: questions,
      missingCount: effectiveMissing,
    );

    if (!mounted) return;

    setState(() {
      _isGenerating = false;
      _generatedCodeKey = code;
    });
  }

  void _handleSearchQuiz() async {
    final code = _enterCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isSearchingQuiz = true;
      _loadedQuiz = null;
      _hasAlreadyAttempted = false;
      _enterQuizError = null;
    });

    final quiz = await TeacherQuizService().fetchQuiz(code);
    final username = CurrentUser.username ?? "Student";
    final attempted = await TeacherQuizService().hasUserAttemptedQuiz(code, username);

    if (!mounted) return;

    setState(() {
      _isSearchingQuiz = false;
      if (quiz != null) {
        _loadedQuiz = quiz;
        _hasAlreadyAttempted = attempted;
      } else {
        _enterQuizError = "No quiz found for code '$code'. Check and try again.";
      }
    });
  }

  void _startQuizBattle() {
    if (_loadedQuiz == null || _hasAlreadyAttempted) return;
    final quizToPlay = _loadedQuiz!;
    Navigator.pop(context); // Close dialog

    if (widget.onStartBattle != null) {
      widget.onStartBattle!(quizToPlay);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherBattleScreen(
            characterIndex: widget.characterIndex,
            quiz: quizToPlay,
          ),
        ),
      );
    }
  }

  void _handleLoadScores() async {
    final code = _scoresCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoadingScores = true;
      _loadedScores = null;
      _scoresError = null;
    });

    final scores = await TeacherQuizService().fetchScores(code);

    if (!mounted) return;

    setState(() {
      _isLoadingScores = false;
      if (scores.isNotEmpty) {
        _loadedScores = scores;
      } else {
        _scoresError = "No student scores found for code '$code' yet.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E281A).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8FBC8F), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TEACHER NPC",
                    style: TextStyle(
                      color: Color(0xFFE8F5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 3 Main Tab Buttons / Boxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(child: _buildTabBox(0, "Generate")),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTabBox(1, "Enter")),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTabBox(2, "Scores")),
                ],
              ),
            ),

            const Divider(color: Color(0xFF324C2C), height: 16),

            // Tab Content Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: _buildCurrentTabBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBox(int index, String label) {
    final bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF131A11),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF81C784) : const Color(0xFF324C2C),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabBody() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildGenerateTab();
      case 1:
        return _buildEnterTab();
      case 2:
      default:
        return _buildScoresTab();
    }
  }

  // ===========================================================================
  // 1. GENERATE TAB (Password Protected & 3 Questions)
  // ===========================================================================
  Widget _buildGenerateTab() {
    if (!_isTeacherAuthenticated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TEACHER AUTHENTICATION REQUIRED",
            style: TextStyle(
              color: Color(0xFF81C784),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please enter the teacher password to generate new quiz questions:",
            style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 11),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Enter password",
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF131A11),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF324C2C)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF324C2C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF81C784)),
              ),
            ),
          ),
          if (_authError != null) ...[
            const SizedBox(height: 6),
            Text(
              _authError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _verifyPassword,
              child: const Text(
                "VERIFY PASSWORD",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    final maxAllowedMissing = _calculateMaxAllowedMissing();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "CREATE NEW QUIZ (3 QUESTIONS)",
              style: TextStyle(
                color: Color(0xFF81C784),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "TEACHER MODE",
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Game Type Selection
        const Text("1. Select Game Type:", style: TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: "Missing Letter",
                isSelected: _selectedGameType == 'missing_letter',
                onTap: () => setState(() => _selectedGameType = 'missing_letter'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip(
                label: "Caesar Matrix",
                isSelected: _selectedGameType == 'caesar_matrix',
                onTap: () => setState(() => _selectedGameType = 'caesar_matrix'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Difficulty Selection
        const Text("2. Select Difficulty Level:", style: TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: "Easy (120s)",
                isSelected: _selectedDifficulty == 'easy',
                onTap: () => setState(() => _selectedDifficulty = 'easy'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildChoiceChip(
                label: "Medium (90s)",
                isSelected: _selectedDifficulty == 'medium',
                onTap: () => setState(() => _selectedDifficulty = 'medium'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildChoiceChip(
                label: "Hard (60s)",
                isSelected: _selectedDifficulty == 'hard',
                onTap: () => setState(() => _selectedDifficulty = 'hard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3 Questions Inputs
        Text(
          _selectedGameType == 'missing_letter'
              ? "3. Enter 3 Questions & Answer Words:"
              : "3. Enter 3 Decryption Target Words:",
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        for (int i = 0; i < 3; i++) ...[
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF131A11),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF324C2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Question ${i + 1} of 3",
                  style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 10),
                ),
                if (_selectedGameType == 'missing_letter') ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: _definitionControllers[i],
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Question/Definition ${i + 1}",
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                      contentPadding: const EdgeInsets.all(8),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                TextField(
                  controller: _wordControllers[i],
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: _selectedGameType == 'missing_letter'
                        ? "Answer Word ${i + 1} (e.g. SECURITY)"
                        : "Target Word ${i + 1} (e.g. FIREWALL)",
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                    contentPadding: const EdgeInsets.all(8),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_selectedGameType == 'missing_letter') ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("4. Blank Letters Count:", style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text(
                "${min(_selectedMissingCount, maxAllowedMissing)} missing letter(s)",
                style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
          Slider(
            value: min(_selectedMissingCount, maxAllowedMissing).toDouble(),
            min: 1,
            max: maxAllowedMissing.toDouble(),
            divisions: maxAllowedMissing > 1 ? maxAllowedMissing - 1 : 1,
            activeColor: const Color(0xFF81C784),
            inactiveColor: const Color(0xFF324C2C),
            onChanged: (val) => setState(() => _selectedMissingCount = val.toInt()),
          ),
          Text(
            "Note: Words must keep at least 1 visible letter (cannot blank all letters).",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9.5),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF131A11),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF324C2C)),
            ),
            child: const Text(
              "Caesar Shift Rule: Shift is fixed to +3 (matching Quest 7-9). Letters shift +3 positions forward in the alphabet.",
              style: TextStyle(color: Color(0xFFFFD54F), fontSize: 10),
            ),
          ),
        ],

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isGenerating ? null : _handleGenerateQuiz,
            child: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text("GENERATE CODE KEY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),

        if (_generatedCodeKey != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131A11),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF81C784), width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  "QUIZ GENERATED SUCCESSFULLY!",
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _generatedCodeKey!,
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 3.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedCodeKey!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Code key copied to clipboard!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Text(
                  "Share this 6-character Code Key with students to enter in Tab 2.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF324C2C) : const Color(0xFF131A11),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF81C784) : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF81C784) : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. ENTER TAB (Student Mode - 1 Attempt Enforcement)
  // ===========================================================================
  Widget _buildEnterTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ENTER QUIZ CODE KEY",
          style: TextStyle(
            color: Color(0xFF81C784),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Enter the 6-character Code Key provided by your teacher to take the 3-question quiz (1 attempt allowed per account):",
          style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 11),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _enterCodeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. A7B9X2",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 0),
                  filled: true,
                  fillColor: const Color(0xFF131A11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF324C2C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF81C784)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isSearchingQuiz ? null : _handleSearchQuiz,
              child: _isSearchingQuiz
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("FIND QUIZ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),

        if (_enterQuizError != null) ...[
          const SizedBox(height: 8),
          Text(
            _enterQuizError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 11),
          ),
        ],

        if (_loadedQuiz != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131A11),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hasAlreadyAttempted
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF8FBC8F),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "QUIZ FOUND: [${_loadedQuiz!.codeKey}]",
                      style: const TextStyle(
                        color: Color(0xFF81C784),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF324C2C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _loadedQuiz!.difficulty.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Game Mode: ${_loadedQuiz!.gameType == 'missing_letter' ? 'Missing Letter' : 'Caesar Matrix'} (3 Trial Questions)",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 10),

                if (_hasAlreadyAttempted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E2723),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD32F2F)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.lock, color: Color(0xFFFF8A80), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "ATTEMPT ALREADY RECORDED! Only 1 attempt is allowed per account. View Tab 3 (Scores) to see student rankings.",
                            style: TextStyle(
                              color: Color(0xFFFF8A80),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _startQuizBattle,
                      child: const Text(
                        "START BATTLE GAME",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 3. SCORES TAB (Teacher Leaderboard)
  // ===========================================================================
  Widget _buildScoresTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QUIZ LEADERBOARD & SCORES",
          style: TextStyle(
            color: Color(0xFF81C784),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Enter Quiz Code Key to view student rankings and recorded scores:",
          style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 11),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _scoresCodeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. A7B9X2",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 0),
                  filled: true,
                  fillColor: const Color(0xFF131A11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF324C2C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF81C784)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isLoadingScores ? null : _handleLoadScores,
              child: _isLoadingScores
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("VIEW SCORES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),

        if (_scoresError != null) ...[
          const SizedBox(height: 8),
          Text(
            _scoresError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 11),
          ),
        ],

        if (_loadedScores != null) ...[
          const SizedBox(height: 14),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _loadedScores!.length,
            itemBuilder: (context, index) {
              final entry = _loadedScores![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A11),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF324C2C)),
                ),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 13,
                    backgroundColor: index == 0
                        ? const Color(0xFFFFD54F) // 1st Gold
                        : (index == 1
                            ? const Color(0xFFCFD8DC) // 2nd Silver
                            : (index == 2
                                ? const Color(0xFFFF8A65) // 3rd Bronze
                                : const Color(0xFF2E7D32))),
                    child: Text(
                      "#${index + 1}",
                      style: TextStyle(
                        color: index <= 2 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  title: Text(
                    entry.username,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  subtitle: Text(
                    "Time: ${entry.timeTakenSeconds}s",
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  trailing: Text(
                    "${entry.score} pts",
                    style: const TextStyle(
                      color: Color(0xFF81C784),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
