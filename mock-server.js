const http = require('http');
const url = require('url');

const args = process.argv.slice(2);
const portIndex = args.indexOf('--port');
const originIndex = args.indexOf('--origin');
const ttlIndex = args.indexOf('--ttl');

const PORT = portIndex !== -1 ? parseInt(args[portIndex + 1], 10) : 8080;
const ALLOWED_ORIGIN = originIndex !== -1 ? args[originIndex + 1] : 'http://localhost:5555';
const TOKEN_TTL_SEC = ttlIndex !== -1 ? parseInt(args[ttlIndex + 1], 10) : 900; // по умолчанию 15 минут

// База пользователей (пароли в открытом виде для мок-сервера)
let users = [
  { id: 1, username: 'admin', password: 'Password123!', fullName: 'Алексей Администраторов', role: 'admin' },
  { id: 2, username: 'librarian', password: 'Password123!', fullName: 'Елена Библиотекарева', role: 'librarian' },
  { id: 3, username: 'reader', password: 'Password123!', fullName: 'Иван Читателев', role: 'reader' },
];

let nextUserId = 4;

let books = [
  { id: 1, title: 'Война и мир', isbn: '978-5-389-06256-6', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [1, 2], copiesTotal: 5, copiesAvailable: 3, deletedAt: null },
  { id: 2, title: 'Преступление и наказание', isbn: '978-5-17-090630-7', year: 1866, pages: 672, publisherId: 2, authorIds: [2], genreIds: [1], copiesTotal: 4, copiesAvailable: 2, deletedAt: null },
  { id: 3, title: '1984', isbn: '978-5-17-080115-2', year: 1949, pages: 320, publisherId: 2, authorIds: [3], genreIds: [3], copiesTotal: 8, copiesAvailable: 6, deletedAt: null },
  { id: 4, title: 'Мастер и Маргарита', isbn: '978-5-389-01686-6', year: 1967, pages: 480, publisherId: 1, authorIds: [4], genreIds: [1, 4], copiesTotal: 6, copiesAvailable: 1, deletedAt: null },
  { id: 5, title: '451 градус по Фаренгейту', isbn: '978-5-17-077074-8', year: 1953, pages: 256, publisherId: 2, authorIds: [5], genreIds: [3], copiesTotal: 7, copiesAvailable: 5, deletedAt: null },
];
let nextBookId = 6;

let loans = [
  { id: 1, userId: 3, bookId: 1, bookTitle: 'Война и мир', issueDate: '2026-09-15', dueDate: '2026-10-15', status: 'active' },
  { id: 2, userId: 3, bookId: 4, bookTitle: 'Мастер и Маргарита', issueDate: '2026-09-20', dueDate: '2026-10-20', status: 'active' },
];
let nextLoanId = 3;

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  });
  res.end(JSON.stringify(data));
}

// Генерация и парсинг токенов
function createToken(user, ttlSeconds) {
  const exp = Math.floor(Date.now() / 1000) + ttlSeconds;
  return Buffer.from(JSON.stringify({ id: user.id, username: user.username, role: user.role, exp })).toString('base64');
}

function verifyAuth(req) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) return { error: 401, message: 'Отсутствует токен авторизации' };
  const raw = authHeader.substring(7);
  try {
    const payload = JSON.parse(Buffer.from(raw, 'base64').toString('utf8'));
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) {
      return { error: 401, message: 'Срок действия токена истёк' };
    }
    const user = users.find(u => u.id === payload.id);
    if (!user) return { error: 401, message: 'Пользователь не найден' };
    return { user: { ...user, role: payload.role } }; // роль берётся из подписанного токена сервера!
  } catch (e) {
    return { error: 401, message: 'Невалидный токен' };
  }
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query;

  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    });
    return res.end();
  }

  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    let parsedBody = {};
    if (body) {
      try { parsedBody = JSON.parse(body); } catch (_) {}
    }

    if (pathname === '/api/__health') {
      return sendJson(res, 200, { status: 'ok', time: new Date().toISOString() });
    }

    // --- АУТЕНТИФИКАЦИЯ ---
    if (pathname === '/api/auth/login' && req.method === 'POST') {
      const { username, password } = parsedBody;
      const user = users.find(u => u.username === username && u.password === password);
      if (!user) {
        return sendJson(res, 401, { message: 'Неверный логин или пароль' });
      }
      const accessToken = createToken(user, TOKEN_TTL_SEC);
      const refreshToken = createToken(user, 7 * 86400);
      const { password: _, ...safeUser } = user;
      return sendJson(res, 200, { accessToken, refreshToken, user: safeUser });
    }

    if (pathname === '/api/auth/register' && req.method === 'POST') {
      const { username, password, fullName } = parsedBody;
      if (!username || !password || !fullName) {
        return sendJson(res, 422, { message: 'Заполните все обязательные поля' });
      }
      if (users.some(u => u.username === username)) {
        return sendJson(res, 409, { message: 'Пользователь с таким логином уже существует' });
      }
      const newUser = { id: nextUserId++, username, password, fullName, role: 'reader' };
      users.push(newUser);
      const accessToken = createToken(newUser, TOKEN_TTL_SEC);
      const refreshToken = createToken(newUser, 7 * 86400);
      const { password: _, ...safeUser } = newUser;
      return sendJson(res, 201, { accessToken, refreshToken, user: safeUser });
    }

    if (pathname === '/api/auth/refresh' && req.method === 'POST') {
      const { refreshToken } = parsedBody;
      if (!refreshToken) return sendJson(res, 401, { message: 'Требуется refreshToken' });
      try {
        const payload = JSON.parse(Buffer.from(refreshToken, 'base64').toString('utf8'));
        const user = users.find(u => u.id === payload.id);
        if (!user) return sendJson(res, 401, { message: 'Пользователь не найден' });
        const newAccess = createToken(user, TOKEN_TTL_SEC);
        const newRefresh = createToken(user, 7 * 86400);
        return sendJson(res, 200, { accessToken: newAccess, refreshToken: newRefresh });
      } catch (e) {
        return sendJson(res, 401, { message: 'Недействительный refreshToken' });
      }
    }

    if (pathname === '/api/auth/me' && req.method === 'GET') {
      const auth = verifyAuth(req);
      if (auth.error) return sendJson(res, auth.error, { message: auth.message });
      const { password: _, ...safeUser } = auth.user;
      return sendJson(res, 200, safeUser);
    }

    // --- ПРОВЕРКА АВТОРИЗАЦИИ ДЛЯ ЗАКРЫТЫХ МАРШРУТОВ ---
    const auth = verifyAuth(req);
    if (auth.error) return sendJson(res, auth.error, { message: auth.message });
    const currentUser = auth.user;

    // --- АДМИНИСТРАТОР: Управление пользователями (/api/admin/users) ---
    if (pathname === '/api/admin/users' && req.method === 'GET') {
      if (currentUser.role !== 'admin') {
        return sendJson(res, 403, { message: 'Недостаточно прав. Требуется роль Администратор' });
      }
      return sendJson(res, 200, users.map(u => ({ id: u.id, username: u.username, fullName: u.fullName, role: u.role })));
    }

    const roleChangeMatch = pathname.match(/^\/api\/admin\/users\/(\d+)\/role$/);
    if (roleChangeMatch && req.method === 'PATCH') {
      if (currentUser.role !== 'admin') {
        return sendJson(res, 403, { message: 'Недостаточно прав для изменения ролей' });
      }
      const uid = parseInt(roleChangeMatch[1], 10);
      const target = users.find(u => u.id === uid);
      if (!target) return sendJson(res, 404, { message: 'Пользователь не найден' });
      target.role = parsedBody.role || target.role;
      return sendJson(res, 200, { id: target.id, username: target.username, role: target.role });
    }

    // --- ЧИТАТЕЛЬ: Выдачи (/api/reader/loans) ---
    if (pathname === '/api/reader/loans' && req.method === 'GET') {
      const userLoans = loans.filter(l => l.userId === currentUser.id);
      return sendJson(res, 200, userLoans);
    }

    const extendLoanMatch = pathname.match(/^\/api\/reader\/loans\/(\d+)\/extend$/);
    if (extendLoanMatch && req.method === 'POST') {
      const lid = parseInt(extendLoanMatch[1], 10);
      const loan = loans.find(l => l.id === lid && l.userId === currentUser.id);
      if (!loan) return sendJson(res, 404, { message: 'Выдача не найдена' });
      loan.dueDate = '2026-11-15';
      return sendJson(res, 200, loan);
    }

    // --- БИБЛИОТЕКАРЬ: Выдачи (/api/librarian/loans) ---
    if (pathname === '/api/librarian/loans' && req.method === 'GET') {
      if (currentUser.role !== 'librarian' && currentUser.role !== 'admin') {
        return sendJson(res, 403, { message: 'Недостаточно прав. Доступно только библиотекарю' });
      }
      return sendJson(res, 200, loans);
    }

    if (pathname === '/api/librarian/loans' && req.method === 'POST') {
      if (currentUser.role !== 'librarian' && currentUser.role !== 'admin') {
        return sendJson(res, 403, { message: 'Недостаточно прав' });
      }
      const newLoan = {
        id: nextLoanId++,
        userId: parsedBody.userId || 3,
        bookId: parsedBody.bookId || 1,
        bookTitle: parsedBody.bookTitle || 'Книга',
        issueDate: new Date().toISOString().substring(0, 10),
        dueDate: '2026-11-01',
        status: 'active'
      };
      loans.push(newLoan);
      return sendJson(res, 201, newLoan);
    }

    // --- КНИГИ (CRUD с проверкой ролей) ---
    if (pathname === '/api/books' && req.method === 'GET') {
      let list = books.filter(b => query.includeDeleted === 'true' ? true : b.deletedAt === null);
      if (query.search) {
        const q = query.search.toLowerCase();
        list = list.filter(b => b.title.toLowerCase().includes(q) || b.isbn.toLowerCase().includes(q));
      }
      const page = parseInt(query.page || '1', 10);
      const size = parseInt(query.size || '10', 10);
      const from = (page - 1) * size;
      return sendJson(res, 200, { items: list.slice(from, from + size), page, size, total: list.length });
    }

    if (pathname === '/api/books' && req.method === 'POST') {
      // Читатель не может создавать книги!
      if (currentUser.role === 'reader') {
        return sendJson(res, 403, { message: 'Читателям запрещено добавлять книги' });
      }
      const created = {
        id: nextBookId++,
        title: parsedBody.title || 'Новая книга',
        isbn: parsedBody.isbn || '000-0-00',
        year: parseInt(parsedBody.year || 2024, 10),
        pages: parseInt(parsedBody.pages || 100, 10),
        publisherId: 1, authorIds: [1], genreIds: [1],
        copiesTotal: 5, copiesAvailable: 5, deletedAt: null
      };
      books.push(created);
      return sendJson(res, 201, created);
    }

    const bookMatch = pathname.match(/^\/api\/books\/(\d+)(\/restore)?$/);
    if (bookMatch) {
      const id = parseInt(bookMatch[1], 10);
      const isRestore = bookMatch[2] === '/restore';
      const book = books.find(b => b.id === id);
      if (!book) return sendJson(res, 404, { message: 'Книга не найдена' });

      if (isRestore && req.method === 'POST') {
        // Восстановление доступно только администратору
        if (currentUser.role !== 'admin') {
          return sendJson(res, 403, { message: 'Только администратор может восстанавливать записи' });
        }
        book.deletedAt = null;
        return sendJson(res, 200, book);
      }

      if (req.method === 'GET') return sendJson(res, 200, book);

      if (req.method === 'DELETE') {
        // Проверка: hard delete доступен только администратору (ПУНКТ 17 методички!)
        if (query.hard === 'true') {
          if (currentUser.role !== 'admin') {
            console.log(`[CORS/RBAC Guard] Попытка несанкционированного удаления пользователем с ролью '${currentUser.role}'`);
            return sendJson(res, 403, { message: 'Физическое удаление разрешено исключительно Администратору' });
          }
          books = books.filter(b => b.id !== id);
          return sendJson(res, 204, null);
        } else {
          // Мягкое удаление доступно библиотекарю и админу
          if (currentUser.role === 'reader') {
            return sendJson(res, 403, { message: 'Недостаточно прав для удаления книги' });
          }
          book.deletedAt = new Date().toISOString();
          return sendJson(res, 204, null);
        }
      }
    }

    // Авторы
    if (pathname === '/api/authors' && req.method === 'GET') {
      return sendJson(res, 200, { items: [], page: 1, size: 10, total: 0 });
    }

    return sendJson(res, 404, { message: 'Эндпоинт не найден' });
  });
});

server.listen(PORT, () => {
  console.log(`[Mock Server PR5] Работает на http://localhost:${PORT}/api`);
  console.log(`[Mock Server PR5] TTL токена: ${TOKEN_TTL_SEC} сек | CORS origin: ${ALLOWED_ORIGIN}`);
});
