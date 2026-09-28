import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';

/// Имя пользователя по его идентификатору.
///
/// Нужно, чтобы на карточке товара показывать «Взял: Иван», а не UID.
/// Сначала смотрим локальный кэш (мгновенно, работает офлайн), и только
/// если его ещё нет — идём в сеть. Так на первом запуске приложения,
/// пока синхронизация не успела залить `users`, имя всё равно найдётся.
final userNameProvider =
    FutureProvider.family<String?, String>((ref, userId) async {
  final repository = ref.watch(authRepositoryProvider);

  final cached = await repository.getCachedUserById(userId);
  if (cached != null) return cached.name;

  final remote = await repository.getUserById(userId);
  return remote?.name;
});
