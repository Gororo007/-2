import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/library_card.dart';
import '../models/publisher.dart';
import '../models/reader.dart';

final seedPublishers = [
  const Publisher(id: 1, name: 'Азбука', city: 'Санкт-Петербург', website: 'azbooka.ru'),
  const Publisher(id: 2, name: 'АСТ', city: 'Москва', website: 'ast.ru'),
  const Publisher(id: 3, name: 'Эксмо', city: 'Москва', website: 'eksmo.ru'),
];

final seedGenres = [
  const Genre(id: 1, name: 'Классика', description: 'Мировая классическая литература'),
  const Genre(id: 2, name: 'Роман', description: 'Художественные романы'),
  const Genre(id: 3, name: 'Антиутопия', description: 'Социально-политическая фантастика'),
  const Genre(id: 4, name: 'Мистика', description: 'Магический реализм и мистика'),
  const Genre(id: 5, name: 'Драматургия', description: 'Пьесы и драматические произведения'),
];

final seedAuthors = [
  const Author(id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', birthYear: 1828),
  const Author(id: 2, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия', birthYear: 1821),
  const Author(id: 3, firstName: 'Джордж', lastName: 'Оруэлл', country: 'Великобритания', birthYear: 1903),
  const Author(id: 4, firstName: 'Михаил', lastName: 'Булгаков', country: 'Россия', birthYear: 1891),
  const Author(id: 5, firstName: 'Рэй', lastName: 'Брэдбери', country: 'США', birthYear: 1920),
  const Author(id: 6, firstName: 'Габриэль', lastName: 'Гарсиа Маркес', country: 'Колумбия', birthYear: 1927),
  const Author(id: 7, firstName: 'Антон', lastName: 'Чехов', country: 'Россия', birthYear: 1860),
  const Author(id: 8, firstName: 'Эрих Мария', lastName: 'Ремарк', country: 'Германия', birthYear: 1898),
];

final seedBooks = [
  const Book(id: 1, title: 'Война и мир', isbn: '978-5-389-06256-6', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [1, 2], copiesTotal: 5, copiesAvailable: 3),
  const Book(id: 2, title: 'Преступление и наказание', isbn: '978-5-17-090630-7', year: 1866, pages: 672, publisherId: 2, authorIds: [2], genreIds: [1], copiesTotal: 4, copiesAvailable: 2),
  const Book(id: 3, title: '1984', isbn: '978-5-17-080115-2', year: 1949, pages: 320, publisherId: 2, authorIds: [3], genreIds: [3], copiesTotal: 8, copiesAvailable: 6),
  const Book(id: 4, title: 'Мастер и Маргарита', isbn: '978-5-389-01686-6', year: 1967, pages: 480, publisherId: 1, authorIds: [4], genreIds: [1, 4], copiesTotal: 6, copiesAvailable: 1),
  const Book(id: 5, title: '451 градус по Фаренгейту', isbn: '978-5-17-077074-8', year: 1953, pages: 256, publisherId: 2, authorIds: [5], genreIds: [3], copiesTotal: 7, copiesAvailable: 5),
  const Book(id: 6, title: 'Сто лет одиночества', isbn: '978-5-17-087082-0', year: 1967, pages: 480, publisherId: 2, authorIds: [6], genreIds: [1, 4], copiesTotal: 3, copiesAvailable: 0),
  const Book(id: 7, title: 'Вишнёвый сад', isbn: '978-5-389-02283-6', year: 1904, pages: 96, publisherId: 1, authorIds: [7], genreIds: [5], copiesTotal: 4, copiesAvailable: 4),
  const Book(id: 8, title: 'На Западном фронте без перемен', isbn: '978-5-17-084224-7', year: 1929, pages: 288, publisherId: 2, authorIds: [8], genreIds: [1, 2], copiesTotal: 5, copiesAvailable: 2),
];

final seedReaders = [
  Reader(
    id: 1,
    fullName: 'Иван Иванов',
    email: 'ivanov@example.com',
    phone: '+7 999 111-22-33',
    card: LibraryCard(
      id: 1,
      cardNumber: 'CARD-1001',
      issuedAt: DateTime(2025, 1, 15),
      expiresAt: DateTime(2027, 1, 15),
    ),
  ),
  Reader(
    id: 2,
    fullName: 'Анна Смирнова',
    email: 'smirnova@example.com',
    phone: '+7 999 444-55-66',
    card: LibraryCard(
      id: 2,
      cardNumber: 'CARD-1002',
      issuedAt: DateTime(2025, 3, 10),
      expiresAt: DateTime(2027, 3, 10),
    ),
  ),
];
