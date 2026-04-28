import 'package:flutter/material.dart' show showAdaptiveDialog;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/todo.dart';
import '../providers/todo_list_notifier.dart';

// 항목 클릭 시 진입하는 수정 다이얼로그. 저장/삭제는 Notifier를 통해 UseCase로 위임한다.
Future<void> showTodoEditDialog({
  required BuildContext context,
  required Todo todo,
}) {
  return showAdaptiveDialog<void>(
    context: context,
    builder: (_) => _TodoEditDialog(todo: todo),
  );
}

class _TodoEditDialog extends ConsumerStatefulWidget {
  const _TodoEditDialog({required this.todo});

  final Todo todo;

  @override
  ConsumerState<_TodoEditDialog> createState() => _TodoEditDialogState();
}

class _TodoEditDialogState extends ConsumerState<_TodoEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  // 다이얼로그 내부 일시 UI 상태(저장 전 미반영 값)이므로 setState 사용이 허용된다.
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(
      text: widget.todo.description ?? '',
    );
    _dueDate = widget.todo.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showFToast(context: context, title: const Text('제목은 비울 수 없습니다.'));
      return;
    }
    final description = _descriptionController.text.trim();
    final updated = widget.todo.copyWith(
      title: title,
      description: description.isEmpty ? null : description,
      dueDate: _dueDate,
    );
    try {
      await ref.read(todoListProvider.notifier).save(updated);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      showFToast(context: context, title: Text(failure.message));
    }
  }

  Future<void> _delete() async {
    try {
      await ref
          .read(todoListProvider.notifier)
          .delete(widget.todo.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      showFToast(context: context, title: Text(failure.message));
    }
  }

  Future<void> _pickDueDate() async {
    // forui FCalendar 다이얼로그 진입을 위한 단순 날짜 선택. 미선택 시 null 유지.
    DateTime? temp = _dueDate;
    final selected = await showAdaptiveDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return FDialog(
          title: const Text('마감일 선택'),
          body: SizedBox(
            height: 320,
            width: 320,
            child: FCalendar(
              control: FCalendarControl.managedDate(
                initial: temp,
                onChange: (date) => temp = date,
              ),
              start: DateTime(2000),
              end: DateTime(2100),
            ),
          ),
          actions: [
            FButton(
              onPress: () => Navigator.of(ctx).pop(temp),
              child: const Text('선택'),
            ),
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  void _clearDueDate() => setState(() => _dueDate = null);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final dueDateLabel = _dueDate == null
        ? '마감일 없음'
        : DateFormat('yyyy-MM-dd').format(_dueDate!);

    return FDialog(
      title: const Text('할일 수정'),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FTextField(
            key: const Key('todo_edit_title'),
            control: FTextFieldControl.managed(controller: _titleController),
            hint: '제목',
          ),
          const SizedBox(height: 12),
          FTextField(
            key: const Key('todo_edit_description'),
            control: FTextFieldControl.managed(
              controller: _descriptionController,
            ),
            hint: '메모 (선택)',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  dueDateLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              if (_dueDate != null)
                FButton(
                  variant: FButtonVariant.ghost,
                  onPress: _clearDueDate,
                  child: const Text('지우기'),
                ),
              const SizedBox(width: 4),
              FButton(
                key: const Key('todo_edit_due_date'),
                variant: FButtonVariant.outline,
                onPress: _pickDueDate,
                child: const Text('마감일'),
              ),
            ],
          ),
        ],
      ),
      direction: Axis.horizontal,
      actions: [
        FButton(
          key: const Key('todo_edit_save'),
          onPress: _save,
          child: const Text('저장'),
        ),
        FButton(
          key: const Key('todo_edit_delete'),
          variant: FButtonVariant.destructive,
          onPress: _delete,
          child: const Text('삭제'),
        ),
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }
}
