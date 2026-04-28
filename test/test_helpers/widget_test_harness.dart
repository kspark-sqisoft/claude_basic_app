import 'dart:async';

import 'package:claude_basic_app/features/todos/data/providers.dart';
import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:claude_basic_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:claude_basic_app/core/error/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 테스트 픽스처에서 사용할 Override 타입을 가져온다.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:forui/forui.dart';
import 'package:fpdart/fpdart.dart';

// 위젯 테스트 전용 in-memory repository. 스트림으로 실시간 변경을 흘려보낸다.
class FakeTodoRepository implements TodoRepository {
  FakeTodoRepository({List<Todo>? initial})
    : _todos = [...?initial],
      _controller =
          StreamController<Either<Failure, List<Todo>>>.broadcast();

  final List<Todo> _todos;
  final StreamController<Either<Failure, List<Todo>>> _controller;

  List<Todo> get current => List.unmodifiable(_todos);

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(Right(List.unmodifiable(_todos)));
  }

  @override
  Stream<Either<Failure, List<Todo>>> watchAll() async* {
    // 구독 시점의 스냅샷을 즉시 흘려보낸 뒤 후속 변경 이벤트로 이어붙인다.
    yield Right(List.unmodifiable(_todos));
    yield* _controller.stream;
  }

  @override
  Future<Either<Failure, Unit>> add(Todo todo) async {
    _todos.add(todo);
    _emit();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> update(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index < 0) {
      return const Left(Failure.database('not found'));
    }
    _todos[index] = todo;
    _emit();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    _todos.removeWhere((t) => t.id == id);
    _emit();
    return const Right(unit);
  }

  void dispose() => _controller.close();
}

// 테스트에서 ProviderScope + FTheme + MaterialApp를 한 번에 감싸는 헬퍼.
Widget wrapForTest(
  Widget child, {
  FakeTodoRepository? repository,
  List<Override> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      if (repository != null)
        todoRepositoryProvider.overrideWith((ref) async => repository),
      ...extraOverrides,
    ],
    child: MaterialApp(
      builder: (context, child) => FTheme(
        data: FThemes.zinc.light.desktop,
        child: FToaster(child: child!),
      ),
      home: child,
    ),
  );
}
