import '../models/procedure.dart';
import 'package:flutter/material.dart';

final List<Procedure> procedures = [
  Procedure(
    key: 'lost_cin',
    title: 'Lost CIN',
    description: 'Report a lost ID card and request a replacement',
    steps: [
      'Go to municipality',
      'Fill declaration',
      'Submit documents',
      'Wait for approval'
    ],
    requiredDocuments: [
      'Old CIN if available',
      'Photo',
      'Declaration form'
    ],
    cost: 'Free',
    timeRequired: '3 days',
    whereToGo: 'Municipal Office',
    importantNotes: 'Bring photocopies',
    icon: Icons.credit_card,
    keywords: [
      'cin',
      'id',
      'identity',
      'lost',
      'lost id',
      'carte',
      'carte identité',
      'بطاقة تعريف',
      'ضاعت'
    ],
  ),

  Procedure(
    key: 'passport',
    title: 'Passport Application',
    description: 'Apply for a Tunisian passport',
    steps: [
      'Fill form',
      'Submit documents',
      'Pay fees',
      'Wait processing'
    ],
    requiredDocuments: [
      'CIN',
      'Photos',
      'Form'
    ],
    cost: '60 TND',
    timeRequired: '2–4 weeks',
    whereToGo: 'Passport Office',
    importantNotes: 'Biometric photo required',
    icon: Icons.book,
    keywords: [
      'passport',
      'passeport',
      'جواز سفر',
      'travel'
    ],
  ),
];