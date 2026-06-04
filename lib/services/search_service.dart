import '../models/procedure.dart';

class SearchService {
  static List<Procedure> search(
    List<Procedure> all,
    String query,
  ) {
    final q = query.toLowerCase().trim();

    if (q.isEmpty) return all;

    return all.where((p) {
      final text = [
        p.title,
        p.description,
        p.key,
        ...p.keywords,
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }
}