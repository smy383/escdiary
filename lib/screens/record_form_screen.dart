import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/escape_record.dart';
import '../models/detail_memo.dart';
import '../providers/record_provider.dart';
import '../widgets/rating_bar.dart';

class RecordFormScreen extends StatefulWidget {
  final EscapeRecord? record;

  const RecordFormScreen({super.key, this.record});

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _themeNameController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _branchNameController;
  late final TextEditingController _playTimeController;
  late final TextEditingController _playerCountController;
  late final TextEditingController _hintCountController;
  late final TextEditingController _clearTimeController;
  late final TextEditingController _contentController;

  late DateTime _playDate;
  late bool _isCleared;
  late ClearTimeType _clearTimeType;

  // 평점
  late double _ratingInterior;
  late double _ratingSatisfaction;
  late double _ratingPuzzle;
  late double _ratingStory;
  late double _ratingProduction;

  // 상세 메모
  late List<DetailMemo> _detailMemos;
  final Map<int, TextEditingController> _detailMemoControllers = {};

  bool _isLoading = false;

  bool get isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;

    _themeNameController = TextEditingController(text: record?.themeName ?? '');
    _storeNameController = TextEditingController(text: record?.storeName ?? '');
    _branchNameController =
        TextEditingController(text: record?.branchName ?? '');
    _playTimeController =
        TextEditingController(text: record?.playTime.toString() ?? '60');
    _playerCountController =
        TextEditingController(text: record?.playerCount.toString() ?? '2');
    _hintCountController =
        TextEditingController(text: record?.hintCount?.toString() ?? '');
    _clearTimeController =
        TextEditingController(text: record?.clearTime ?? '');
    _contentController = TextEditingController(text: record?.content ?? '');

    _playDate = record?.playDate ?? DateTime.now();
    _isCleared = record?.isCleared ?? true;
    _clearTimeType = record?.clearTimeType ?? ClearTimeType.remaining;

    _ratingInterior = record?.ratingInterior ?? 0;
    _ratingSatisfaction = record?.ratingSatisfaction ?? 0;
    _ratingPuzzle = record?.ratingPuzzle ?? 0;
    _ratingStory = record?.ratingStory ?? 0;
    _ratingProduction = record?.ratingProduction ?? 0;

    // 상세 메모 초기화
    _detailMemos = List.from(record?.detailMemos ?? []);
    for (int i = 0; i < _detailMemos.length; i++) {
      _detailMemoControllers[i] = TextEditingController(text: _detailMemos[i].content);
    }
  }

  @override
  void dispose() {
    _themeNameController.dispose();
    _storeNameController.dispose();
    _branchNameController.dispose();
    _playTimeController.dispose();
    _playerCountController.dispose();
    _hintCountController.dispose();
    _clearTimeController.dispose();
    _contentController.dispose();
    for (var controller in _detailMemoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '기록 수정' : '새 기록'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecord,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 기본 정보 섹션
            _buildSectionTitle(context, '기본 정보'),
            const SizedBox(height: 12),

            // 테마명
            TextFormField(
              controller: _themeNameController,
              decoration: const InputDecoration(
                labelText: '테마명 *',
                hintText: '테마 이름을 입력하세요',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '테마명을 입력해주세요';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // 매장명
            TextFormField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: '매장명 *',
                hintText: '매장 이름을 입력하세요',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '매장명을 입력해주세요';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // 지점명
            TextFormField(
              controller: _branchNameController,
              decoration: const InputDecoration(
                labelText: '지점명',
                hintText: '지점명을 입력하세요 (선택)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),

            // 플레이 정보 섹션
            _buildSectionTitle(context, '플레이 정보'),
            const SizedBox(height: 12),

            // 플레이 날짜
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('플레이 날짜'),
              subtitle: Text(DateFormat('yyyy년 MM월 dd일').format(_playDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),
            const Divider(),

            // 인원수, 제한시간
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _playerCountController,
                    decoration: const InputDecoration(
                      labelText: '인원 *',
                      suffixText: '명',
                      prefixIcon: Icon(Icons.group_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '인원 입력';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 1) {
                        return '1명 이상';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _playTimeController,
                    decoration: const InputDecoration(
                      labelText: '제한시간 *',
                      suffixText: '분',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '시간 입력';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 탈출 여부
            Card(
              child: SwitchListTile(
                title: const Text('탈출 성공'),
                subtitle: Text(_isCleared ? '성공했어요!' : '다음에는 꼭 성공!'),
                value: _isCleared,
                onChanged: (value) => setState(() => _isCleared = value),
                secondary: Icon(
                  _isCleared ? Icons.check_circle : Icons.cancel,
                  color: _isCleared ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 힌트 사용
            TextFormField(
              controller: _hintCountController,
              decoration: const InputDecoration(
                labelText: '힌트 사용',
                suffixText: '회',
                prefixIcon: Icon(Icons.lightbulb_outline),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // 클리어 시간 타입 선택
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '클리어 시간',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<ClearTimeType>(
                            segments: const [
                              ButtonSegment(
                                value: ClearTimeType.remaining,
                                label: Text('남은 시간'),
                                icon: Icon(Icons.hourglass_bottom),
                              ),
                              ButtonSegment(
                                value: ClearTimeType.elapsed,
                                label: Text('걸린 시간'),
                                icon: Icon(Icons.timer),
                              ),
                            ],
                            selected: {_clearTimeType},
                            onSelectionChanged: (Set<ClearTimeType> selected) {
                              setState(() => _clearTimeType = selected.first);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clearTimeController,
                      decoration: InputDecoration(
                        labelText: _clearTimeType == ClearTimeType.remaining
                            ? '남은 시간'
                            : '걸린 시간',
                        hintText: '45:30',
                        prefixIcon: Icon(
                          _clearTimeType == ClearTimeType.remaining
                              ? Icons.hourglass_bottom
                              : Icons.timer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 평점 섹션
            _buildSectionTitle(context, '평점'),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    RatingBar(
                      label: '인테리어',
                      rating: _ratingInterior,
                      onRatingChanged: (v) =>
                          setState(() => _ratingInterior = v),
                    ),
                    const SizedBox(height: 16),
                    RatingBar(
                      label: '만족도',
                      rating: _ratingSatisfaction,
                      onRatingChanged: (v) =>
                          setState(() => _ratingSatisfaction = v),
                    ),
                    const SizedBox(height: 16),
                    RatingBar(
                      label: '문제',
                      rating: _ratingPuzzle,
                      onRatingChanged: (v) =>
                          setState(() => _ratingPuzzle = v),
                    ),
                    const SizedBox(height: 16),
                    RatingBar(
                      label: '스토리',
                      rating: _ratingStory,
                      onRatingChanged: (v) =>
                          setState(() => _ratingStory = v),
                    ),
                    const SizedBox(height: 16),
                    RatingBar(
                      label: '연출',
                      rating: _ratingProduction,
                      onRatingChanged: (v) =>
                          setState(() => _ratingProduction = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 간단 메모 섹션
            _buildSectionTitle(context, '간단 메모'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '간단 메모',
                hintText: '간단한 메모를 기록하세요',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: 24),

            // 상세 메모 섹션
            _buildSectionTitle(context, '상세 메모'),
            const SizedBox(height: 12),
            _buildDetailMemoSection(context),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildDetailMemoSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 기존 상세 메모 목록
        ..._detailMemos.asMap().entries.map((entry) {
          final index = entry.key;
          final memo = entry.value;
          return _buildDetailMemoCard(context, memo, index);
        }),

        // 메모 추가 버튼들
        const SizedBox(height: 12),
        Text(
          '메모 추가',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MemoType.values.map((type) {
            return ActionChip(
              avatar: Icon(_getMemoTypeIcon(type), size: 18),
              label: Text(type.label),
              onPressed: () => _addDetailMemo(type),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getMemoTypeIcon(MemoType type) {
    switch (type) {
      case MemoType.story:
        return Icons.auto_stories;
      case MemoType.production:
        return Icons.theater_comedy;
      case MemoType.puzzle:
        return Icons.extension;
      case MemoType.answer:
        return Icons.check_circle_outline;
    }
  }

  Color _getMemoTypeColor(MemoType type) {
    switch (type) {
      case MemoType.story:
        return Colors.blue;
      case MemoType.production:
        return Colors.purple;
      case MemoType.puzzle:
        return Colors.orange;
      case MemoType.answer:
        return Colors.green;
    }
  }

  Widget _buildDetailMemoCard(BuildContext context, DetailMemo memo, int index) {
    final theme = Theme.of(context);
    final color = _getMemoTypeColor(memo.type);

    // 컨트롤러가 없으면 생성
    if (!_detailMemoControllers.containsKey(index)) {
      _detailMemoControllers[index] = TextEditingController(text: memo.content);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(_getMemoTypeIcon(memo.type), size: 18, color: color),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    memo.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                  onPressed: () => _removeDetailMemo(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              controller: _detailMemoControllers[index],
              decoration: InputDecoration(
                hintText: '${memo.type.label} 내용을 입력하세요',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              minLines: 3,
              onChanged: (value) {
                _updateDetailMemoContent(index, value);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addDetailMemo(MemoType type) {
    // 해당 타입의 다음 번호 계산
    final existingCount = _detailMemos.where((m) => m.type == type).length;
    final newNumber = existingCount + 1;

    final newMemo = DetailMemo(
      type: type,
      number: newNumber,
      content: '',
    );

    setState(() {
      _detailMemos.add(newMemo);
      final newIndex = _detailMemos.length - 1;
      _detailMemoControllers[newIndex] = TextEditingController();
    });
  }

  void _removeDetailMemo(int index) {
    setState(() {
      _detailMemoControllers[index]?.dispose();
      _detailMemoControllers.remove(index);
      _detailMemos.removeAt(index);

      // 인덱스 재조정
      final newControllers = <int, TextEditingController>{};
      for (int i = 0; i < _detailMemos.length; i++) {
        if (_detailMemoControllers.containsKey(i)) {
          newControllers[i] = _detailMemoControllers[i]!;
        } else if (_detailMemoControllers.containsKey(i + 1)) {
          newControllers[i] = _detailMemoControllers[i + 1]!;
        }
      }
      _detailMemoControllers.clear();
      _detailMemoControllers.addAll(newControllers);

      // 번호 재계산
      _recalculateMemoNumbers();
    });
  }

  void _updateDetailMemoContent(int index, String content) {
    if (index < _detailMemos.length) {
      _detailMemos[index] = _detailMemos[index].copyWith(content: content);
    }
  }

  void _recalculateMemoNumbers() {
    final typeCounts = <MemoType, int>{};
    for (int i = 0; i < _detailMemos.length; i++) {
      final type = _detailMemos[i].type;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      _detailMemos[i] = _detailMemos[i].copyWith(number: typeCounts[type]!);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _playDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _playDate = picked);
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final record = EscapeRecord(
        id: widget.record?.id,
        themeName: _themeNameController.text.trim(),
        storeName: _storeNameController.text.trim(),
        branchName: _branchNameController.text.trim().isNotEmpty
            ? _branchNameController.text.trim()
            : null,
        playDate: _playDate,
        playTime: int.parse(_playTimeController.text),
        playerCount: int.parse(_playerCountController.text),
        isCleared: _isCleared,
        hintCount: _hintCountController.text.isNotEmpty
            ? int.parse(_hintCountController.text)
            : null,
        clearTime: _clearTimeController.text.trim().isNotEmpty
            ? _clearTimeController.text.trim()
            : null,
        clearTimeType: _clearTimeType,
        ratingInterior: _ratingInterior,
        ratingSatisfaction: _ratingSatisfaction,
        ratingPuzzle: _ratingPuzzle,
        ratingStory: _ratingStory,
        ratingProduction: _ratingProduction,
        content: _contentController.text.trim().isNotEmpty
            ? _contentController.text.trim()
            : null,
        detailMemos: _detailMemos.where((m) => m.content.isNotEmpty).toList(),
        createdAt: widget.record?.createdAt,
      );

      final provider = context.read<RecordProvider>();
      if (isEditing) {
        await provider.updateRecord(record);
      } else {
        await provider.addRecord(record);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? '기록이 수정되었습니다' : '기록이 저장되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
