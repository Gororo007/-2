import 'package:flutter_test/flutter_test.dart';
import 'package:library_system/models/book.dart';
import 'package:library_system/models/book_query.dart';
import 'package:library_system/models/page_result.dart';
import 'package:library_system/models/role.dart';
import 'package:library_system/models/user.dart';

void main() {
  group('Модульные тесты для Практической работы №6', () {
    test('1. Разбор модели Book.fromJson с дефолтными значениями', () {
      final book = Book.fromJson({'id': 10, 'title': 'Тест'});
      expect(book.id, 10);
      expect(book.title, 'Тест');
      expect(book.pages, 0);
      expect(book.isDeleted, isFalse);
    });

    test('2. Метод copyWith книги сохраняет неизменённые поля', () {
      const original = Book(
          id: 1,
          title: 'Книга',
          isbn: '111',
          year: 2020,
          pages: 150,
          publisherId: 1,
          authorIds: [],
          genreIds: [],
          copiesTotal: 5,
          copiesAvailable: 5);
      final updated = original.copyWith(title: 'Новое название');
      expect(updated.title, 'Новое название');
      expect(updated.isbn, '111');
      expect(updated.year, 2020);
    });

    test('3. Модель PageResult корректно рассчитывает totalPages и переходы',
        () {
      const page = PageResult(items: [1, 2], page: 2, size: 2, total: 6);
      expect(page.totalPages, 3);
      expect(page.hasPrevious, isTrue);
      expect(page.hasNext, isTrue);
    });

    test('4. Модель PageResult.empty возвращает пустой список', () {
      final empty = PageResult<Book>.empty();
      expect(empty.items.isEmpty, isTrue);
      expect(empty.total, 0);
      expect(empty.page, 1);
    });

    test('5. Изменение фильтра в BookQuery сбрасывает страницу на 1', () {
      const query = BookQuery(page: 5, search: 'старое');
      final newQuery = query.copyWith(search: 'новое');
      expect(newQuery.page, 1);
      expect(newQuery.search, 'новое');
    });

    test('6. Equality и hashCode для BookQuery', () {
      const q1 = BookQuery(search: 'test', page: 2);
      const q2 = BookQuery(search: 'test', page: 2);
      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
    });

    test('7. Разбор роли из строки Role.fromString', () {
      expect(Role.fromString('admin'), Role.admin);
      expect(Role.fromString('librarian'), Role.librarian);
      expect(Role.fromString('reader'), Role.reader);
      expect(Role.fromString('unknown'), Role.reader);
    });

    test('8. Сериализация AppUser в JSON и обратно', () {
      const user = AppUser(
          id: 5, username: 'petr', fullName: 'Петр', role: Role.librarian);
      final json = user.toJson();
      final fromJson = AppUser.fromJson(json);
      expect(fromJson.id, user.id);
      expect(fromJson.role, Role.librarian);
    });
  });
}
