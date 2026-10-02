import '../models/publisher.dart';

abstract interface class PublisherRepository {
  Future<List<Publisher>> findAll({bool includeDeleted = false});
  Future<Publisher?> findById(int id);
  Future<Publisher> create(Publisher publisher);
  Future<Publisher> update(Publisher publisher);
  Future<void> deleteWithCheck(int id);
  Future<void> restore(int id);
}
