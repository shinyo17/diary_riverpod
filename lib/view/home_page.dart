import 'package:diary_riverpod/model/diary.dart';
import 'package:diary_riverpod/provider/diary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:table_calendar/table_calendar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  DateTime selectedDate = DateTime.now();

  TextEditingController createCtrl = TextEditingController();

  TextEditingController updateCtrl = TextEditingController();

  CalendarFormat calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final diaryPvd = ref.watch(diaryProvider);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _calendar(),
            Divider(),
            Expanded(
              child: diaryPvd.diaryList.isEmpty ? _whenListIsEmpty() : _diaryListView(),
            ),
          ],
        ),
      ),
      floatingActionButton: _floatingActionButton(context),
    );
  }

  FloatingActionButton _floatingActionButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Color(0xFF92A8D1),
      child: Icon(Icons.create),
      onPressed: () {
        showTextFieldDialog(
          "일기 작성",
          (_) {
            createDiary();
            Navigator.pop(context);
          },
          createCtrl,
          TextButton(
            onPressed: () {
              createDiary();
              Navigator.pop(context);
            },
            child: const Text(
              "작성",
              style: TextStyle(fontSize: 18, color: Color(0xFF92A8D1)),
            ),
          ),
        );
      },
    );
  }

  void createDiary() {
    // 앞뒤 공백 삭제
    String newText = createCtrl.text.trim();
    if (newText.isNotEmpty) {
      ref.read(diaryProvider.notifier).create(newText, selectedDate);
      createCtrl.text = "";
    }
  }

  ListView _diaryListView() {
    return ListView.separated(
      itemCount: 1,
      separatorBuilder: (BuildContext context, int index) {
        return const Divider(height: 1);
      },
      itemBuilder: (BuildContext context, int index) {
        final diaryList = ref.watch(diaryProvider.notifier).getByDate(selectedDate);
        Diary diary = diaryList[diaryList.length - index - 1];

        return ListTile(
          title: Text(
            diary.text,
            style: const TextStyle(color: Colors.black, fontSize: 24),
          ),
          trailing: Text(
            DateFormat("kk:mm").format(
              diary.createdAt,
            ),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          onTap: () {
            showTextFieldDialog("일기 수정", (v) {
              updateDiary(diary);
              Navigator.pop(context);
            },
                updateCtrl,
                TextButton(
                  child: Text(
                    "수정",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF92A8D1),
                    ),
                  ),
                  onPressed: () {
                    // 수정하기
                    updateDiary(diary);
                    Navigator.pop(context);
                  },
                ),
                diary: diary);
          },
          onLongPress: () {
            showDeleteDialog(diary);
          },
        );
      },
    );
  }

  void updateDiary(Diary diary) {
    String newText = updateCtrl.text.trim();
    if (newText.isNotEmpty) {
      ref.read(diaryProvider.notifier).update(
            diary.createdAt,
            newText,
          );
    }
  }

  Center _whenListIsEmpty() {
    return const Center(
      child: Text(
        "한 줄 일기를 작성해 주세요.",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _calendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: DateTime.now(),
      calendarFormat: calendarFormat,
      onFormatChanged: (format) {
        setState(() {
          calendarFormat = format;
        });
      },
      eventLoader: (date) {
        return ref.watch(diaryProvider.notifier).getByDate(date);
      },
      calendarStyle: const CalendarStyle(
        todayTextStyle: TextStyle(color: Colors.black),
        todayDecoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
      selectedDayPredicate: (day) {
        return isSameDay(selectedDate, day);
      },
      onDaySelected: (_, focusedDay) {
        setState(() {
          selectedDate = focusedDay;
        });
      },
    );
  }

  void showTextFieldDialog(
    String title,
    void Function(String)? onSubmitted,
    TextEditingController textCtrl,
    TextButton submitButton, {
    Diary? diary,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        if (diary != null) {
          textCtrl.text = diary.text;
        }
        return AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            controller: textCtrl,
            cursorColor: Color(0xFF92A8D1),
            decoration: const InputDecoration(
              hintText: "한 줄 일기를 작성해 주세요.",
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF92A8D1)),
              ),
            ),
            onSubmitted: onSubmitted,
          ),
          actions: [
            TextButton(
              child: const Text(
                "취소",
                style: TextStyle(
                  color: Color(0xFF92A8D1),
                  fontSize: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            submitButton,
          ],
        );
      },
    );
  }

  void showDeleteDialog(Diary diary) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("일기 삭제"),
          content: Text('"${diary.text}"를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text(
                "취소",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF92A8D1),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text(
                "삭제",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF92A8D1),
                ),
              ),
              onPressed: () {
                ref.read(diaryProvider.notifier).delete(diary.createdAt);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
