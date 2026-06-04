import 'package:admin_process/core/database/database_helper.dart';
import 'package:admin_process/models/procedure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseHelper.rankProcedures', () {
    final procedures = [
      Procedure(
        key: 'passport_new',
        title: 'Passeport',
        description: 'Demande de passeport',
        steps: const ['Fill form'],
        requiredDocuments: const ['CIN', 'Photo biometrque'],
        cost: '80 dinars',
        timeRequired: '15 jours',
        whereToGo: 'Centre de securite',
        importantNotes: 'Presence personnelle obligatoire',
        keywords: const ['passport', 'passeport', 'جواز سفر'],
      ),
      Procedure(
        key: 'lost_cin',
        title: 'Perte de CIN',
        description: 'Remplacement de la CIN',
        steps: const ['Police', 'Municipalite'],
        requiredDocuments: const ['Photo', 'Certificat de residence'],
        cost: '15 dinars',
        timeRequired: '7 jours',
        whereToGo: 'Municipalite',
        importantNotes: 'Declaration rapide',
        keywords: const ['cin', 'carte identite', 'بطاقة تعريف'],
      ),
    ];

    test('matches queries across keywords and text accents', () {
      final ranked = DatabaseHelper.rankProcedures(procedures, 'passeport');
      expect(ranked.first.procedure.key, 'passport_new');
    });

    test('matches Arabic keyword queries', () {
      final ranked = DatabaseHelper.rankProcedures(procedures, 'بطاقة تعريف');
      expect(ranked.first.procedure.key, 'lost_cin');
    });
  });
}
