import '../models/reader.dart';

abstract interface class ReaderRepository {
  Future<List<Reader>> findAll({bool includeDeleted = false, String search = ''});
  Future<Reader?> findById(int id);
  Future<Reader> create(Reader reader);
  Future<Reader> update(Reader reader);
  Future<void> softDelete(int id);
  Future<void> restore(int id);
}
