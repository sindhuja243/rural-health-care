import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/symptom_check_model.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

class SymptomCheckerService {
  static final SymptomCheckerService _instance =
      SymptomCheckerService._internal();
  factory SymptomCheckerService() => _instance;
  SymptomCheckerService._internal();

  /// Analyzes symptoms using the callable Firebase Cloud Function `analyzeSymptoms` (powered by Claude).
  /// Falls back to safety-first local triage heuristics if the Cloud Function is not yet deployed.
  Future<SymptomCheckModel> analyzeSymptoms(String symptomsText) async {
    final cleaned = symptomsText.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Please provide a description of symptoms.');
    }

    debugPrint('====================================================');
    debugPrint('[SymptomCheckerService] Analyzing symptoms: "$cleaned"');
    debugPrint('====================================================');

    Map<String, dynamic>? resultData;

    // 1. Attempt Cloud Function execution if Firebase is initialized
    if (FirebaseService.isInitialized) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'analyzeSymptoms',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
        );

        final response = await callable.call<Map<String, dynamic>>({
          'symptomsText': cleaned,
        });

        resultData = response.data;
        debugPrint('[SymptomCheckerService] Cloud Function response received: $resultData');
      } catch (e) {
        debugPrint('[SymptomCheckerService] Cloud Function notice: $e');
        debugPrint('[SymptomCheckerService] Falling back to safety-first clinical triage engine.');
      }
    }

    // 2. Intelligent Safety-First Triage Engine (Fallback when Cloud Function is un-deployed)
    resultData ??= _evaluateSymptomsLocally(cleaned);

    final severity = (resultData['severity'] ?? 'high').toString().toLowerCase();
    final possibleCondition = (resultData['possibleCondition'] ?? 'General Medical Review').toString();
    final remedy = severity == 'low' ? resultData['remedy']?.toString() : null;

    final checkResult = SymptomCheckModel(
      id: 'chk_${DateTime.now().millisecondsSinceEpoch}',
      symptomsText: cleaned,
      severity: severity,
      possibleCondition: possibleCondition,
      remedy: remedy,
      timestamp: DateTime.now(),
    );

    // 3. Save every check to Firestore under patients/{uid}/symptomChecks/{auto-id}
    await _saveCheckToFirestore(checkResult);

    return checkResult;
  }

  /// Evaluates symptoms with clinical safety rules (erring toward "high" severity for any serious red flags)
  Map<String, dynamic> _evaluateSymptomsLocally(String text) {
    final lower = text.toLowerCase();

    // High severity indicators (English, Telugu, Hindi)
    final highSeverityKeywords = [
      // English
      'chest pain', 'heart', 'breath', 'shortness of breath', 'breathing difficulty',
      'dyspnea', 'unconscious', 'fainting', 'stroke', 'bleeding', 'blood',
      'severe pain', 'fracture', 'poison', 'snake', 'bite', 'pregnant', 'pregnancy',
      'convulsion', 'seizure', 'high fever', 'chills', 'vision loss', 'paralysis',
      'suicide', 'vomiting blood', 'cyanosis', 'severe head',

      // Telugu
      'గుండె నొప్పి', 'ఛాతీ నొప్పి', 'శ్వాస', 'శ్వాస ఆడటం లేదు', 'రక్తం',
      'అధిక జ్వరం', 'తీవ్రమైన', 'స్పృహ తప్పడం', 'గర్భిణీ', 'కడుపులో తీవ్ర నొప్పి',
      'పాము కాటు', 'గాయం', 'ఫ్రాక్చర్',

      // Hindi
      'छाती में दर्द', 'सीने में दर्द', 'सांस', 'सांस लेने में तकलीफ',
      'खून', 'तेज बुखार', 'बेहोश', 'गर्भवती', 'सांप का काटना', 'गंभीर'
    ];

    final isHigh = highSeverityKeywords.any((kw) => lower.contains(kw));

    if (isHigh) {
      String condition = 'Acute Medical Condition / అత్యవసర పరిస్థితి';
      if (lower.contains('chest') || lower.contains('heart') || lower.contains('గుండె') || lower.contains('छाती')) {
        condition = 'Potential Cardiac / Respiratory Distress (గుండె / ఛాతీ సంబంధిత సమస్య)';
      } else if (lower.contains('breath') || lower.contains('శ్వాస') || lower.contains('सांस')) {
        condition = 'Acute Respiratory Distress (శ్వాసకోశ సమస్య)';
      } else if (lower.contains('pregnant') || lower.contains('గర్భిణీ') || lower.contains('गर्भवती')) {
        condition = 'Obstetric / Pregnancy Complication (గర్భధారణ అత్యవసర సంరక్షణ)';
      } else if (lower.contains('fever') || lower.contains('జ్వరం') || lower.contains('बुखार')) {
        condition = 'High-Grade Febrile Infection (తీవ్రమైన సంక్రమణ జ్వరం)';
      }

      return {
        'severity': 'high',
        'possibleCondition': condition,
        'remedy': null,
      };
    }

    // Low severity ailments
    if (lower.contains('cough') || lower.contains('cold') || lower.contains('దగ్గు') || lower.contains('జలుబు') || lower.contains('खांसी') || lower.contains('जुकाम')) {
      return {
        'severity': 'low',
        'possibleCondition': 'Mild Seasonal Upper Respiratory Infection / సాధారణ జలుబు, దగ్గు',
        'remedy': 'తులసి, అల్లం మరియు తేనెతో కలిపిన గోరువెచ్చని నీరు లేదా కషాయం త్రాగండి. ఆవిరి పట్టండి మరియు విశ్రాంతి తీసుకోండి. / Drink warm water with ginger, tulsi and honey. Inhale steam and take adequate rest.',
      };
    } else if (lower.contains('stomach') || lower.contains('indigestion') || lower.contains('gas') || lower.contains('కడుపు') || lower.contains('ఉబ్బరం') || lower.contains('पेट')) {
      return {
        'severity': 'low',
        'possibleCondition': 'Mild Gastric Indigestion / సాధారణ జీర్ణ సమస్య',
        'remedy': 'జీలకర్ర నీరు లేదా మజ్జిగ త్రాగండి. తేలికపాటి ఆహారం (ఖిచ్డీ) తీసుకోండి. / Drink warm cumin (jeera) water or buttermilk with a pinch of salt. Eat light, easily digestible food.',
      };
    } else if (lower.contains('headache') || lower.contains('తలనొప్పి') || lower.contains('सिरदर्द')) {
      return {
        'severity': 'low',
        'possibleCondition': 'Mild Tension Headache / అలసట లేదా తలనొప్పి',
        'remedy': 'చీకటి గదిలో ప్రశాంతంగా విశ్రాంతి తీసుకోండి, పుష్కలంగా నీరు త్రాగండి. / Rest in a quiet dark room, stay hydrated with plenty of fluids, and apply a cool cloth to forehead.',
      };
    }

    // Default to Low with general remedy for generic mild inputs
    return {
      'severity': 'low',
      'possibleCondition': 'Mild Malaise / సాధారణ అలసట & శారీరక రుగ్మత',
      'remedy': 'పుష్కలంగా ద్రవాహారం (ORS లేదా కొబ్బరి నీరు) తీసుకోండి మరియు తగినంత విశ్రాంతి పొందండి. / Drink plenty of fluids (boiled water, ORS or coconut water) and take adequate bed rest.',
    };
  }

  /// Saves the check to Firestore at `patients/{uid}/symptomChecks/{auto-id}`
  Future<void> _saveCheckToFirestore(SymptomCheckModel check) async {
    final user = AuthService().currentUser;
    final uid = user?.uid ?? 'user_anonymous';

    debugPrint('[SymptomCheckerService] Saving check to Firestore: patients/$uid/symptomChecks/${check.id}');

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(uid)
            .collection('symptomChecks')
            .doc(check.id)
            .set(check.toMap())
            .timeout(const Duration(seconds: 10));

        debugPrint('[SymptomCheckerService] Check successfully logged in Firestore for UID: $uid');
      } catch (e) {
        debugPrint('[SymptomCheckerService] Firestore log notice: $e');
      }
    }
  }
}
