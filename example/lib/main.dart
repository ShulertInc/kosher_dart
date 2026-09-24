import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ));

class MyApp extends StatefulWidget {
  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  JewishDate jewishDate = JewishDate();
  JewishCalendar jewishCalendar = JewishCalendar();
  HebrewDateFormatter hebrewDateFormatter = HebrewDateFormatter();
  HebrewDateFormatter translatedDateFormatter = HebrewDateFormatter()
    ..setHebrewFormat(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kosher Dart'),
      ),
      body: GestureDetector(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: jewishCalendar.getLocalDate(),
            firstDate: DateTime(jewishCalendar.getLocalDate().year - 100),
            lastDate: DateTime(jewishCalendar.getLocalDate().year + 100),
          );

          if (pickedDate != null) {
            setState(() {
              jewishCalendar.setGregorianDate(pickedDate);
              jewishDate.setGregorianDate(pickedDate);
            });
          }
        },
        child: Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(' תאריך לעוזי: ${DateFormat("dd.MM.yyyy")
                      .format(jewishDate.getLocalDate())}'),
              Text('תאריך עברי: ${hebrewDateFormatter.format(jewishDate)}'),
              Text('פרשת השבוע: ${hebrewDateFormatter.formatParshah(jewishCalendar.getUpcomingParshah())}'),
              Text('דף יומי: ${hebrewDateFormatter.formatDafYomiBavli(
                      jewishCalendar.getDafYomiBavli())}'),
              Text('Daf Yomi: ${hebrewDateFormatter.formatDafYomiBavli(
                      jewishCalendar.getDafYomiBavli())}'),
              Text('Translated Hebrew Date: ${translatedDateFormatter.format(jewishDate)}'),
              Text('Cloned Translated Hebrew Date: ${translatedDateFormatter.format(jewishDate.clone())}'),
              Text('Parasha of the week: ${translatedDateFormatter.formatParshah(jewishCalendar.getUpcomingParshah())}'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    hebrewDateFormatter.setHebrewFormat(true);
    hebrewDateFormatter.setUseGershGershayim(true);
    super.initState();
  }
}
