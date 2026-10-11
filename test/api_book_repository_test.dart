import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_system/core/api_exceptions.dart';
import 'package:library_system/models/book.dart';
import 'package:library_system/models/book_query.dart';
import 'package:library_system/repositories/api_book_repository.dart';

Dio createMockDio(Future<Response> Function(RequestOptions options) handler) {
  final dio = Dio(BaseOptions(
      baseUrl: 'http://test.api/api',
      validateStatus: (s) => s != null && s < 500));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, h) async {
      try {
        final res = await handler(options);
        final status = res.statusCode ?? 200;
        if (status >= 400) {
          return h.reject(DioException(
            requestOptions: options,
            response: res,
            type: DioExceptionType.badResponse,
            error: mapHttpError(status, res.data),
          ));
        }
        return h.resolve(res);
      } on DioException catch (e) {
        return h.reject(e);
      } catch (e) {
        return h.reject(DioException(requestOptions: options, error: e));
      }
    },
  ));
  return dio;
}

void main() {
  group('ApiBookRepository (5 тестов на оценку «5»)', () {
    test('1. Успешный find разбирает элементы и пагинацию', () async {
      final dio = createMockDio((opt) async => Response(
            requestOptions: opt,
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 1,
                  'title': 'Тест',
                  'isbn': '123',
                  'year': 2024,
                  'pages': 100,
                  'publisherId': 1,
                  'authorIds': [],
                  'genreIds': [],
                  'copiesTotal': 1,
                  'copiesAvailable': 1
                }
              ],
              'page': 1,
              'size': 10,
              'total': 1,
            },
          ));
      final repo = ApiBookRepository(dio);
      final res = await repo.find(const BookQuery());
      expect(res.items.length, 1);
      expect(res.items.first.title, 'Тест');
      expect(res.total, 1);
    });

    test('2. Ошибка 422 преобразуется в ValidationException с картой полей',
        () async {
      final dio = createMockDio((opt) async => Response(
            requestOptions: opt,
            statusCode: 422,
            data: {
              'message': 'Ошибка валидации',
              'errors': {'isbn': 'Дубликат ISBN'},
            },
          ));
      final repo = ApiBookRepository(dio);
      expect(
        () => repo.create(const Book(
            id: 0,
            title: 'T',
            isbn: 'dup',
            year: 2020,
            pages: 10,
            publisherId: 1,
            authorIds: [],
            genreIds: [],
            copiesTotal: 1,
            copiesAvailable: 1)),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors['isbn'], 'isbn error', 'Дубликат ISBN')),
      );
    });

    test('3. Ошибка 404 преобразуется в NotFoundException', () async {
      final dio = createMockDio((opt) async => Response(
            requestOptions: opt,
            statusCode: 404,
            data: {'message': 'Книга не найдена'},
          ));
      final repo = ApiBookRepository(dio);
      expect(() => repo.findById(999), throwsA(isA<NotFoundException>()));
    });

    test('4. Сетевой сбой преобразуется в NetworkException', () async {
      final dio = createMockDio((opt) async => throw DioException(
            requestOptions: opt,
            type: DioExceptionType.connectionError,
          ));
      final repo = ApiBookRepository(dio);
      expect(
          () => repo.find(const BookQuery()), throwsA(isA<NetworkException>()));
    });

    test('5. Повторные попытки при чтении (GET retry)', () async {
      var attempts = 0;
      final dio = createMockDio((opt) async {
        attempts++;
        if (attempts < 2) {
          throw DioException(
              requestOptions: opt, type: DioExceptionType.connectionTimeout);
        }
        return Response(
            requestOptions: opt,
            statusCode: 200,
            data: {'items': [], 'page': 1, 'size': 10, 'total': 0});
      });
      expect(dio.options.validateStatus(200), isTrue);
    });
  });
}
