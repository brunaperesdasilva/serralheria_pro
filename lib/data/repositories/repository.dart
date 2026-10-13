abstract interface class Repository<T> {
  Future<List<T>> getAll();
  Stream<List<T>> watchAll();
  Future<T> save(T value);
  Future<void> delete(int id);
}
