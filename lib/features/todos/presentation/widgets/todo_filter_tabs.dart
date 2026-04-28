import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../providers/todo_filter_provider.dart';

// 전체/미완료/완료 필터 탭. 상태는 TodoFilterNotifier에 보관하고 lifted control로 동기화한다.
class TodoFilterTabs extends ConsumerWidget {
  const TodoFilterTabs({super.key});

  static const _filters = [
    TodoFilter.all,
    TodoFilter.pending,
    TodoFilter.completed,
  ];

  static const _labels = {
    TodoFilter.all: '전체',
    TodoFilter.pending: '미완료',
    TodoFilter.completed: '완료',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(todoFilterProvider);
    final index = _filters.indexOf(current);

    return FTabs(
      control: FTabControl.lifted(
        index: index,
        onChange: (i) =>
            ref.read(todoFilterProvider.notifier).set(_filters[i]),
      ),
      children: [
        for (final filter in _filters)
          FTabEntry(
            label: Text(_labels[filter]!, key: Key('todo_filter_${filter.name}')),
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}
