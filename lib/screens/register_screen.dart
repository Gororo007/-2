import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _hasMinLength = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _loading = false;
  String? _error;

  void _onPasswordChanged(String pass) {
    setState(() {
      _hasMinLength = pass.length >= 8;
      _hasDigit = pass.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = pass.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasMinLength || !_hasDigit || !_hasSpecialChar) {
      setState(
          () => _error = 'Пароль не соответствует требованиям безопасности');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthNotifier>().register(
            _usernameCtrl.text.trim(),
            _passwordCtrl.text,
            _fullNameCtrl.text.trim(),
          );
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text('Регистрация читателя',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _fullNameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'ФИО', prefixIcon: Icon(Icons.badge)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Укажите ФИО' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Логин', prefixIcon: Icon(Icons.person)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Придумайте логин' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Пароль', prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                      onChanged: _onPasswordChanged,
                      validator: (v) => v!.isEmpty ? 'Придумайте пароль' : null,
                    ),
                    const SizedBox(height: 12),
                    // ПУНКТ 6: Усиленная проверка пароля в реальном времени
                    _RuleTile(
                        checked: _hasMinLength, text: 'Не менее 8 символов'),
                    _RuleTile(checked: _hasDigit, text: 'Содержит цифру (0-9)'),
                    _RuleTile(
                        checked: _hasSpecialChar,
                        text: 'Содержит спецсимвол (!@#\$...)'),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Зарегистрироваться'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Уже есть аккаунт? Войти'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final bool checked;
  final String text;
  const _RuleTile({required this.checked, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(checked ? Icons.check_circle : Icons.circle_outlined,
              size: 16, color: checked ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color:
                      checked ? Colors.green.shade800 : Colors.grey.shade700)),
        ],
      ),
    );
  }
}
