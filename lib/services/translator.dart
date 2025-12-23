import 'package:flutter/material.dart';

class Translator {
  // Current Language State (Default English)
  static String currentLang = 'en';

  // The Dictionary
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'FixCity',
      'report_issue': 'Report Complaint',
      'dashboard': 'City Dashboard',
      'submit': 'SUBMIT REPORT',
      'camera': 'Take Photo',
      'gallery': 'Choose from Gallery',
      'desc_hint': 'Describe the issue...',
      'analysis': 'AI Assessment',
      'urgency': 'Urgency',
      'dept': 'Department',
      'severity': 'Severity',
      'admin_controls': 'ADMIN CONTROLS',
      'resolved': 'RESOLVED',
      'working': 'IN PROGRESS',
    },
    'ta': {
      // Tamil
      'app_title': 'ஃபிக்ஸ் சிட்டி',
      'report_issue': 'புகாரளிக்கவும்',
      'dashboard': 'நகர பலகை',
      'submit': 'சமர்ப்பிக்கவும்',
      'camera': 'புகைப்படம் எடு',
      'gallery': 'கேலரியில் தேர்வு செய்',
      'desc_hint': 'விளக்கம் தரவும்...',
      'analysis': 'AI ஆய்வு',
      'urgency': 'அவசரம்',
      'dept': 'துறை',
      'severity': 'தீவிரம்',
      'admin_controls': 'நிர்வாகக் கட்டுப்பாடுகள்',
      'resolved': 'தீர்க்கப்பட்டது',
      'working': 'வேலை நடக்கிறது',
    },
    'hi': {
      // Hindi
      'app_title': 'फिक्स सिटी',
      'report_issue': 'शिकायत दर्ज करें',
      'dashboard': 'सिटी डैशबोर्ड',
      'submit': 'रिपोर्ट भेजें',
      'camera': 'फोटो लें',
      'gallery': 'गैलरी से चुनें',
      'desc_hint': 'समस्या का वर्णन करें...',
      'analysis': 'AI मूल्यांकन',
      'urgency': 'तात्कालिकता',
      'dept': 'विभाग',
      'severity': 'गंभीरता',
      'admin_controls': 'व्यवस्थापक नियंत्रण',
      'resolved': 'समाधान हो गया',
      'working': 'कार्य जारी है',
    },
  };

  // The Magic Function
  static String t(String key) {
    return _localizedValues[currentLang]?[key] ?? key;
  }
}
