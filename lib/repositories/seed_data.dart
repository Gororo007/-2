import '../models/author.dart';
import '../models/book.dart';

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
  const Book(id: 9, title: 'Анна Каренина', isbn: '978-5-389-01524-1', year: 1877, pages: 864, publisherId: 1, authorIds: [1], genreIds: [1], copiesTotal: 3, copiesAvailable: 1),
  const Book(id: 10, title: 'Идиот', isbn: '978-5-17-090631-4', year: 1869, pages: 640, publisherId: 2, authorIds: [2], genreIds: [1], copiesTotal: 4, copiesAvailable: 3),
  const Book(id: 11, title: 'Скотный двор', isbn: '978-5-17-080116-9', year: 1945, pages: 128, publisherId: 2, authorIds: [3], genreIds: [3], copiesTotal: 10, copiesAvailable: 7),
  const Book(id: 12, title: 'Белая гвардия', isbn: '978-5-389-01687-3', year: 1925, pages: 352, publisherId: 1, authorIds: [4], genreIds: [1, 2], copiesTotal: 3, copiesAvailable: 2),
  const Book(id: 13, title: 'Марсианские хроники', isbn: '978-5-17-077075-5', year: 1950, pages: 320, publisherId: 2, authorIds: [5], genreIds: [3], copiesTotal: 5, copiesAvailable: 4),
  const Book(id: 14, title: 'Три товарища', isbn: '978-5-17-084225-4', year: 1936, pages: 480, publisherId: 2, authorIds: [8], genreIds: [1], copiesTotal: 6, copiesAvailable: 5),
  const Book(id: 15, title: 'Братья Карамазовы', isbn: '978-5-17-090632-1', year: 1880, pages: 928, publisherId: 2, authorIds: [2], genreIds: [1], copiesTotal: 3, copiesAvailable: 1),
  const Book(id: 16, title: 'Чайка', isbn: '978-5-389-02284-3', year: 1896, pages: 80, publisherId: 1, authorIds: [7], genreIds: [5], copiesTotal: 2, copiesAvailable: 2),
  const Book(id: 17, title: 'Собачье сердце', isbn: '978-5-389-01688-0', year: 1925, pages: 160, publisherId: 1, authorIds: [4], genreIds: [1, 3], copiesTotal: 8, copiesAvailable: 6),
  const Book(id: 18, title: 'Триумфальная арка', isbn: '978-5-17-084226-1', year: 1945, pages: 512, publisherId: 2, authorIds: [8], genreIds: [1], copiesTotal: 4, copiesAvailable: 0),
  const Book(id: 19, title: 'Вино из одуванчиков', isbn: '978-5-17-077076-2', year: 1957, pages: 320, publisherId: 2, authorIds: [5], genreIds: [1], copiesTotal: 5, copiesAvailable: 3),
  const Book(id: 20, title: 'Палата № 6', isbn: '978-5-389-02285-0', year: 1892, pages: 112, publisherId: 1, authorIds: [7], genreIds: [1], copiesTotal: 4, copiesAvailable: 3),
  const Book(id: 21, title: 'Воскресение', isbn: '978-5-389-01525-8', year: 1899, pages: 544, publisherId: 1, authorIds: [1], genreIds: [1], copiesTotal: 3, copiesAvailable: 2),
];
