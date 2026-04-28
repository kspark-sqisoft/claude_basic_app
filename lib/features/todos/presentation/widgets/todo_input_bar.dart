import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../../core/error/failure.dart';
import '../providers/todo_list_notifier.dart';

// 리스트 상단 인라인 입력바. 빈 문자열은 제출하지 않고, 실패는 토스트로 표시한다.
class TodoInputBar extends ConsumerStatefulWidget {
  const TodoInputBar({super.key});

  @override
  ConsumerState<TodoInputBar> createState() => _TodoInputBarState();
}

class _TodoInputBarState extends ConsumerState<TodoInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    try {
      await ref.read(todoListProvider.notifier).add(title: title);
      _controller.clear();
    } on Failure catch (failure) {
      if (!mounted) return;
      showFToast(
        context: context,
        title: Text(failure.message),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FTextField(
            key: const Key('todo_input_field'),
            control: FTextFieldControl.managed(controller: _controller),
            hint: '새 할일을 입력하고 Enter…',
            textInputAction: TextInputAction.done,
            onSubmit: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        FButton(
          key: const Key('todo_input_add_button'),
          onPress: _submit,
          child: const Text('추가'),
        ),
      ],
    );
  }
}
