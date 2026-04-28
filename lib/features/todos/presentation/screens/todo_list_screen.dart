import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

// step 5에서 본격 구현 예정인 자리표시자 화면.
class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(title: const Text('Todo')),
      child: const Center(child: Text('coming soon')),
    );
  }
}
