import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/procedure.dart';
import '../../models/user_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('maak.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    const storage = FlutterSecureStorage();
    String? key = await storage.read(key: 'db_encryption_key');
    if (key == null) {
      key = '32characterstrongrandomkey12345678';
      await storage.write(key: 'db_encryption_key', value: key);
    }

    return openDatabase(
      path,
      password: key,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async => _ensureProcedureSeedData(db),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE procedures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        steps TEXT,
        required_documents TEXT,
        cost TEXT,
        time_required TEXT,
        where_to_go TEXT,
        important_notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile (
        id INTEGER PRIMARY KEY,
        full_name TEXT,
        cin TEXT,
        birth_date TEXT,
        phone TEXT,
        address TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _ensureProcedureSeedData(db);
    }
  }

  Future<void> _ensureProcedureSeedData(Database db) async {
    final countResult =
        await db.rawQuery('SELECT COUNT(*) AS count FROM procedures');
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count > 0) return;

    for (final procedure in _defaultProcedures) {
      await db.insert(
        'procedures',
        procedure.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<int> saveProfile(UserProfile profile) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile (
        id INTEGER PRIMARY KEY,
        full_name TEXT,
        cin TEXT,
        birth_date TEXT,
        phone TEXT,
        address TEXT
      )
    ''');
    return await db.insert(
      'profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getProfile() async {
    final db = await database;

    Future<UserProfile?> queryIfExists(String table) async {
      final exists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        [table],
      );
      if (exists.isEmpty) return null;

      final result = await db.query(table, limit: 1);
      if (result.isEmpty) return null;
      return UserProfile.fromMap(result.first);
    }

    return await queryIfExists('profil') ?? await queryIfExists('profile');
  }

  Future<List<Procedure>> searchProcedures(String query) async {
    final db = await database;
    await _ensureProcedureSeedData(db);
    final results = await db.query('procedures');
    final procedures = results.map(Procedure.fromMap).toList();

    final ranked = rankProcedures(procedures, query);
    return ranked.map((entry) => entry.procedure).toList();
  }

  Future<List<Procedure>> getAllProcedures() async {
    final db = await database;
    await _ensureProcedureSeedData(db);
    final results = await db.query('procedures', orderBy: 'title ASC');
    return results.map(Procedure.fromMap).toList();
  }

  Future<Procedure?> getProcedure(String key) async {
    final db = await database;
    await _ensureProcedureSeedData(db);

    final maps = await db.query(
      'procedures',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Procedure.fromMap(maps.first);
  }

  static List<ProcedureMatch> rankProcedures(
    List<Procedure> procedures,
    String query,
  ) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return procedures
          .map((procedure) => ProcedureMatch(procedure: procedure, score: 0))
          .toList();
    }

    final tokens = normalizedQuery
        .split(' ')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();

    final matches = <ProcedureMatch>[];
    for (final procedure in procedures) {
      final haystack = _normalize([
        procedure.key,
        procedure.title,
        procedure.description,
        procedure.cost,
        procedure.timeRequired,
        procedure.whereToGo,
        procedure.importantNotes,
        ...procedure.steps,
        ...procedure.requiredDocuments,
        ...procedure.keywords,
      ].join(' '));

      var score = 0;
      if (haystack.contains(normalizedQuery)) score += 6;
      if (haystack.contains(procedure.key.replaceAll('_', ' '))) score += 1;
      for (final token in tokens) {
        if (haystack.contains(token)) score += 2;
      }

      if (score > 0) {
        matches.add(ProcedureMatch(procedure: procedure, score: score));
      }
    }

    matches.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.procedure.title.compareTo(b.procedure.title);
    });

    return matches;
  }

  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final normalized = lower
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
        .trim();
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }
}

class ProcedureMatch {
  final Procedure procedure;
  final int score;

  const ProcedureMatch({
    required this.procedure,
    required this.score,
  });
}

final List<Procedure> _defaultProcedures = [
  Procedure(
    key: 'lost_cin',
    title: 'Perte de CIN',
    description: 'Remplacement de la carte d\'identite nationale perdue.',
    steps: const [
      'Declarer la perte au poste de police le plus proche.',
      'Constituer le dossier avec photo et justificatifs.',
      'Deposer le dossier a la municipalite.',
      'Payer les frais de remplacement.',
      'Recuperer la nouvelle carte a la date indiquee.',
    ],
    requiredDocuments: const [
      'Photo d\'identite recente',
      'Copie de l\'ancienne CIN si disponible',
      'Certificat de residence',
      'Recu de paiement',
    ],
    cost: '15 dinars',
    timeRequired: '7 a 15 jours',
    whereToGo: 'Poste de police puis municipalite',
    importantNotes: 'Faire la declaration rapidement pour eviter toute utilisation abusive.',
    keywords: const [
      'cin',
      'carte identite',
      'id',
      'perte cin',
      'lost cin',
      'بطاقة تعريف',
      'ضاعت بطاقة',
    ],
  ),
  Procedure(
    key: 'passport_new',
    title: 'Passeport',
    description: 'Demande d\'un nouveau passeport tunisien.',
    steps: const [
      'Remplir le formulaire officiel.',
      'Payer les frais demandes.',
      'Se presenter au centre de securite de reference.',
      'Retirer le passeport a la date de remise.',
    ],
    requiredDocuments: const [
      'CIN',
      'Photo biometrque',
      'Timbre fiscal',
      'Extrait de naissance',
    ],
    cost: '80 dinars',
    timeRequired: '15 jours',
    whereToGo: 'Centre de securite ou service des passeports',
    importantNotes: 'Presence personnelle obligatoire avec les originaux.',
    keywords: const [
      'passport',
      'passeport',
      'جواز سفر',
      'باسبور',
      'travel document',
    ],
  ),
  Procedure(
    key: 'disability_card',
    title: 'Carte handicap',
    description: 'Obtention de la carte de handicap pour les avantages administratifs.',
    steps: const [
      'Prendre rendez-vous avec un medecin specialiste.',
      'Deposer le dossier medical devant la commission competente.',
      'Suivre la validation et retirer la carte aux services sociaux.',
    ],
    requiredDocuments: const [
      'Dossier medical',
      'CIN',
      'Extrait de naissance',
      'Deux photos',
    ],
    cost: 'Gratuit',
    timeRequired: 'Environ 1 mois',
    whereToGo: 'Unite de promotion sociale',
    importantNotes: 'La carte est valable 5 ans avant renouvellement.',
    keywords: const [
      'disability',
      'carte handicap',
      'accessibility',
      'بطاقة إعاقة',
      'اعاقة',
    ],
  ),
];
