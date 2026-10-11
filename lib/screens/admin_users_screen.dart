import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = context.read<Dio>();
      final res = await dio.get('/admin/users');
      if (mounted) setState(() => _users = res.data as List);
    } catch (e) {
      if (mounted) setState(() => _error = 'Ошибка загрузки: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(int id, String newRole) async {
    try {
      final dio = context.read<Dio>();
      await dio.patch('/admin/users/$id/role', data: {'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Роль успешно обновлена')));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка смены роли: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              const Text('Управление пользователями и ролями (Администратор)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('${u['fullName']} (@${u['username']})'),
                        subtitle: Text('Текущая роль: ${u['role']}'),
                        trailing: DropdownButton<String>(
                          value: u['role'],
                          items: const [
                            DropdownMenuItem(
                                value: 'reader', child: Text('Читатель')),
                            DropdownMenuItem(
                                value: 'librarian',
                                child: Text('Библиотекарь')),
                            DropdownMenuItem(
                                value: 'admin', child: Text('Администратор')),
                          ],
                          onChanged: (val) {
                            if (val != null && val != u['role']) {
                              _changeRole(u['id'], val);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
