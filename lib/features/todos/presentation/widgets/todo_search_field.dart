import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../providers/todo_search_query_provider.dart';

// 헤더 우측 검색 입력. provider state를 source-of-truth로 두고, 위젯은 controller만 보유한다.
class TodoSearchField extends ConsumerStatefulWidget {
  const TodoSearchField({super.key});

  @override
  ConsumerState<TodoSearchField> createState() => _TodoSearchFieldState();
}

class _TodoSearchFieldState extends ConsumerState<TodoSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(todoSearchQueryProvider),
    );
    _controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleChange() {
    ref.read(todoSearchQueryProvider.notifier).set(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    // provider의 autoDispose를 막기 위해 widget 생애 동안 listen 유지.
    ref.listen<String>(todoSearchQueryProvider, (_, _) {});
    return SizedBox(
      width: 240,
      child: FTextField(
        key: const Key('todo_search_field'),
        control: FTextFieldControl.managed(controller: _controller),
        hint: '제목 검색',
      ),
    );
  }
}
