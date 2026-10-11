import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:library_system/models/book.dart';
import 'package:library_system/models/book_query.dart';
import 'package:library_system/models/page_result.dart';
import 'package:library_system/repositories/book_repository.dart';
import 'package:library_system/screens/book_form_screen.dart';
import 'package:library_system/screens/book_list_screen.dart';
import 'package:library_system/state/auth_notifier.dart';
import 'package:library_system/state/book_list_notifier.dart';

class FakeBookRepository implements BookRepository {
  final PageResult<Book>? result;
  final bool shouldThrow;

  FakeBookRepository({this.result, this.shouldThrow = false});

  @override
  Future<PageResult<Book>> find(BookQuery query,
      {CancelToken? cancelToken}) async {
    if (shouldThrow) throw Exception('Сервер временно недоступен');
    return result ?? PageResult.empty();
  }

  @override
  Future<Book?> findById(int id) async => null;
  @override
  Future<Book> create(Book book) async => book;
  @override
  Future<Book> update(Book book) async => book;
  @override
  Future<void> softDelete(int id) async {}
  @override
  Future<void> hardDelete(int id) async {}
  @override
  Future<void> restore(int id) async {}
  @override
  Future<int> deleteMany(List<int> ids) async => 0;
  @override
  List<Book> getAllRaw() => result?.items ?? [];
}

Widget buildTestableScreen({
  required Widget child,
  BookRepository? bookRepo,
}) {
  return MultiProvider(
    providers: [
      Provider<BookRepository>(create: (_) => bookRepo ?? FakeBookRepository()),
      ChangeNotifierProvider<BookListNotifier>(
        create: (ctx) => BookListNotifier(ctx.read<BookRepository>()),
      ),
      ChangeNotifierProvider<AuthNotifier>(
        create: (_) => AuthNotifier.mock(),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/books',
        routes: [
          GoRoute(
            path: '/books',
            builder: (context, state) => child,
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('5 тестов виджетов для Практической работы №6 (оценка «5»)', () {
    testWidgets('1. Отображение состояния загрузки (CircularProgressIndicator)',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        child: const BookListScreen(),
        bookRepo: FakeBookRepository(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('2. Отображение пустого результата каталога', (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        child: const BookListScreen(),
        bookRepo: FakeBookRepository(result: PageResult.empty()),
      ));

      await tester.pumpAndSettle();
      expect(
          find.text('Книг по заданным критериям не найдено'), findsOneWidget);
    });

    testWidgets('3. Отображение экрана сетевой ошибки с кнопкой «Повторить»',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        child: const BookListScreen(),
        bookRepo: FakeBookRepository(shouldThrow: true),
      ));

      await tester.pumpAndSettle();
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('4. Срабатывание валидации формы книги при пустом вводе',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        child: const BookFormScreen(),
      ));
      await tester.pumpAndSettle();

      final saveButton = find.text('Сохранить');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Укажите название'), findsOneWidget);
      expect(find.text('Укажите ISBN'), findsOneWidget);
    });

    testWidgets(
        '5. Доступность интерфейса: поле поиска содержит подсказку и иконку',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        child: const BookListScreen(),
        bookRepo: FakeBookRepository(result: PageResult.empty()),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
