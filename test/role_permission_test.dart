import 'package:flutter_test/flutter_test.dart';
import 'package:library_system/models/role.dart';
import 'package:library_system/models/user.dart';

void main() {
  group('Тестирование разграничения прав (ПР5, оценка «5»)', () {
    test('1. Иерархия уровней ролей (Admin > Librarian > Reader)', () {
      expect(Role.admin.level > Role.librarian.level, isTrue);
      expect(Role.librarian.level > Role.reader.level, isTrue);
      expect(Role.reader.level, 1);
    });

    test('2. Читатель не имеет прав библиотекаря или администратора', () {
      const readerUser =
          AppUser(id: 1, username: 'r', fullName: 'R', role: Role.reader);
      final hasLibrarian = readerUser.role.level >= Role.librarian.level;
      final hasAdmin = readerUser.role.level >= Role.admin.level;

      expect(hasLibrarian, isFalse);
      expect(hasAdmin, isFalse);
    });

    test(
        '3. Библиотекарь имеет доступ к каталогу, но не к правам администратора',
        () {
      const libUser =
          AppUser(id: 2, username: 'l', fullName: 'L', role: Role.librarian);
      expect(libUser.role.level >= Role.librarian.level, isTrue);
      expect(libUser.role.level >= Role.admin.level, isFalse);
    });

    test('4. Администратор обладает всеми уровнями прав', () {
      const adminUser =
          AppUser(id: 3, username: 'a', fullName: 'A', role: Role.admin);
      expect(adminUser.role.level >= Role.reader.level, isTrue);
      expect(adminUser.role.level >= Role.librarian.level, isTrue);
      expect(adminUser.role.level >= Role.admin.level, isTrue);
    });

    test(
        '5. Усиленная валидация пароля (минимум 8 символов, цифра, спецсимвол)',
        () {
      bool isValidPassword(String p) {
        return p.length >= 8 &&
            p.contains(RegExp(r'[0-9]')) &&
            p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      }

      expect(isValidPassword('short1!'), isFalse); // < 8
      expect(isValidPassword('password!'), isFalse); // без цифр
      expect(isValidPassword('password123'), isFalse); // без спецсимволов
      expect(isValidPassword('Password123!'), isTrue); // валидный
    });
  });
}
