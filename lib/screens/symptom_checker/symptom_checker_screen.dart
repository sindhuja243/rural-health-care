import 'package:flutter/material.dart';
import '../../models/symptom_check_model.dart';
import '../../services/symptom_checker_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../hospital/find_hospital_screen.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isAnalyzing = false;
  String? _errorMessage;
  SymptomCheckModel? _lastResult;

  final List<Map<String, String>> _sampleChips = [
    {
      'label': '🤧 Mild Cold & Cough / జలుబు & దగ్గు',
      'text': 'I have a mild runny nose and slight dry cough for 1 day. No high fever or chest pain. / నాకు ఒక రోజు నుండి కొద్దిగా జలుబు మరియు పొడి దగ్గు ఉంది.',
    },
    {
      'label': '🚨 Severe Chest Pain / తీవ్రమైన గుండె నొప్పి',
      'text': 'Severe chest tightness radiating to left arm and shortness of breath for past 30 minutes. / గత 30 నిమిషాలుగా ఛాతీలో తీవ్రమైన నొప్పి మరియు శ్వాస తీసుకోవడంలో ఇబ్బందిగా ఉంది.',
    },
    {
      'label': '🍵 Mild Indigestion / కడుపులో ఉబ్బరం',
      'text': 'Mild stomach fullness, bloating and gas after lunch. No severe pain or vomiting. / భోజనం తర్వాత కడుపులో కొద్దిగా ఉబ్బరం మరియు గ్యాస్ ఉంది.',
    },
    {
      'label': '⚠️ High Fever & Chills / తీవ్రమైన జ్వరం',
      'text': 'Very high fever (103 F) with severe body chills, shaking, and extreme weakness. / చలితో కూడిన తీవ్రమైన జ్వరం మరియు తీవ్ర నీరసం.',
    },
  ];

  @override
  void dispose() {
    _symptomsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _analyzeSymptoms() async {
    final text = _symptomsController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage =
            'Please describe your symptoms in words / దయచేసి మీ లక్షణాలను వివరించండి.';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _lastResult = null;
    });

    try {
      final result = await SymptomCheckerService().analyzeSymptoms(text);

      if (!mounted) return;

      setState(() {
        _lastResult = result;
        _isAnalyzing = false;
      });

      // Smooth scroll down to view result card
      await Future.delayed(const Duration(milliseconds: 150));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage =
            'Unable to complete symptom triage: $e\nPlease consult your local ASHA worker or doctor.';
      });
    }
  }

  void _useSample(String sampleText) {
    setState(() {
      _symptomsController.text = sampleText;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Symptom Checker / లక్షణాల తనిఖీ'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryTeal, AppTheme.secondarySky],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gramin AI Triage',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Describe symptoms in Telugu, Hindi or English for rapid rural triage assessment.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Input Container Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note_rounded,
                            color: AppTheme.primaryTeal, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Describe Symptoms / మీ లక్షణాలు చెప్పండి',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Type freely in Telugu (తెలుగు), Hindi (हिंदी), or English:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Multi-line text field
                    TextField(
                      controller: _symptomsController,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'ఉదా: నాకు 2 రోజుల నుంచి జలుబు, గొంతు నొప్పి ఉంది...\n(e.g., I have mild cough and slight headache since morning...)',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted.withValues(alpha: 0.8),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceSecondary,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryTeal,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Sample Chips
                    const Text(
                      'Quick Test Examples / ఉదాహరణలు:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sampleChips.map((chip) {
                        return InkWell(
                          onTap: () => _useSample(chip['text']!),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            child: Text(
                              chip['label']!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Analyze Button
                    CustomButton(
                      text: _isAnalyzing
                          ? 'Analyzing with AI Claude... / విశ్లేషిస్తోంది...'
                          : 'Analyze Symptoms / లక్షణాలను విశ్లేషించండి',
                      icon: _isAnalyzing ? null : Icons.psychology_rounded,
                      isLoading: _isAnalyzing,
                      onPressed: _isAnalyzing ? null : _analyzeSymptoms,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerCoralLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.dangerCoral.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.dangerCoral, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.dangerCoral,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Analysis Results Section
              if (_lastResult != null) ...[
                _buildTriageResultCard(_lastResult!),
              ],

              const SizedBox(height: 20),

              // Safety Disclaimer
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: AppTheme.textMuted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Safety Notice: This AI Triage tool is designed for initial rural guidance, not a medical prescription. In emergencies, call 108.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the triage result card based on Low vs High severity
  Widget _buildTriageResultCard(SymptomCheckModel result) {
    final isLow = result.isLowSeverity;

    if (isLow) {
      // ================= LOW SEVERITY CARD =================
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.successMint.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.successMint.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.successMintLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successMint,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mild / Low Severity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.successMint,
                        ),
                      ),
                      Text(
                        'సాధారణ లక్షణాలు (Non-Emergency)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successMintLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.successMint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 12),

            // Possible Condition
            const Text(
              'Likely Assessment / సాధ్యమైన పరిస్థితి:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.possibleCondition,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Home Remedy Card
            if (result.remedy != null && result.remedy!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTealLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.eco_rounded,
                            color: AppTheme.primaryTealDark, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Suggested Home Remedy / ఇంటి చిట్కా:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryTealDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.remedy!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Critical 2-Day ASHA Follow-up Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // Warm amber notice
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notification_important_rounded,
                      color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '2 రోజుల్లో నయం కాకపోతే ASHA worker ని సంప్రదించండి / If it doesn\'t improve in 2 days, contact your ASHA worker.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // ================= HIGH SEVERITY CARD =================
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.dangerCoral,
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dangerCoral.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Header Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.dangerCoralLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.dangerCoral,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'High Severity / Urgent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.dangerCoral,
                        ),
                      ),
                      Text(
                        'తీవ్రమైన పరిస్థితి (Requires Clinical Care)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerCoral,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'HIGH ALERT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 12),

            // Condition Assessment
            const Text(
              'Identified Concern / గుర్తించిన పరిస్థితి:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.possibleCondition,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppTheme.dangerCoral,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Safety Warning Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.dangerCoralLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.dangerCoral.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'ఈ లక్షణాలు తీవ్రమైనవిగా కనిపిస్తున్నాయి. వెంటనే సమీపంలోని ప్రాథమిక ఆరోగ్య కేంద్రం (PHC) లేదా ఆసుపత్రి వైద్యులను సంప్రదించండి.\nThese symptoms require immediate evaluation by a medical professional.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dangerCoral,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button: Find Hospital (Navigates to FindHospitalScreen)
            CustomButton(
              text: 'Find Hospital / ఆసుపత్రిని కనుగొనండి',
              icon: Icons.local_hospital_rounded,
              backgroundColor: AppTheme.dangerCoral,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FindHospitalScreen(
                      conditionHint: result.possibleCondition,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }
}
