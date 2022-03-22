import 'package:flutter/material.dart';

const int a = 97;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  // List<ExerciseGroup> data = groupsFromJson(inputData);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> inputData = [
    {"id": 1, "order": 1, "order_prefix": ""},
    {"id": 2, "order": 2, "order_prefix": "a"},
    {"id": 3, "order": 2, "order_prefix": "b"},
    {"id": 4, "order": 2, "order_prefix": "c"},
    {"id": 5, "order": 3, "order_prefix": ""},
    {"id": 6, "order": 4, "order_prefix": ""}
  ];
  List<Exercise> data = [];
  _MyHomePageState() {
    data = getExercisesFromJson(inputData);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          itemCount: data.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
                key: Key('$index'),
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  data[index].id == -1
                      ? Text('${data[index].order}:')
                      : data[index].prefix != ''
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
                              child: Text(
                                  '${data[index].prefix}: упражнение №${data[index].id}'),
                            )
                          : Text(
                              '${data[index].order}: упражнение №${data[index].id}'),
                  data[index].id != -1 && data[index].prefix == ''
                      ? PopupMenuButton<ExercisePropetiesChoice>(
                          onSelected: (ExercisePropetiesChoice result) {
                            processExercisePropetiesChoice(result, index);
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<ExercisePropetiesChoice>>[
                            const PopupMenuItem<ExercisePropetiesChoice>(
                              value: ExercisePropetiesChoice.addGroup,
                              child: Text('Создать группу'),
                            ),
                          ],
                        )
                      : Container()
                ]));
          },
          onReorder: (int oldIndex, int newIndex) {
            if (data[oldIndex].id != -1) {
              if (!data[oldIndex].addedWithButton) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }

                  processMoved(oldIndex, newIndex);
                });
              }
            }
          },
        ));
  }

  void processMoved(int oldPos, int newPos) {
    var obj = data.removeAt(oldPos);
    if (obj.prefix == '') {
      for (var i = oldPos; i < data.length; i++) {
        data[i].order--;
      }
    } else if (oldPos > 0 &&
        data.lastIndexWhere((element) => element.order == obj.order) -
                data.indexWhere((element) =>
                    element.id == -1 && element.order == obj.order) <
            2) {
      obj.prefix = '';
      newPos--;
      data.removeWhere((element) =>
          element.id == -1 &&
          element.order == obj.order &&
          element.addedWithButton == false);
    }

    insertMoved(obj, newPos, oldPos);
  }

  void insertMoved(Exercise moved, int newPos, int oldPos) {
    data.insert(newPos, moved);
    if (newPos == 0) {
      data[newPos].order = 1;
      for (var i = newPos + 1; i < data.length; i++) {
        data[i].order++;
      }
    } else if (newPos + 1 == data.length) {
      data[newPos].order = data[newPos - 1].order + 1;
    } else if (data[newPos + 1].prefix == '' && data[newPos - 1].prefix == '' ||
        data[newPos + 1].prefix == '' && data[newPos - 1].prefix != '') {
      data[newPos].order = data[newPos + 1].order;
      for (var i = newPos + 1; i < data.length; i++) {
        data[i].order++;
      }
    } else if ((data[newPos + 1].prefix != '')) {
      data[newPos].order = data[newPos - 1].order;
    }

    placeNewPrefixes();
  }

  void placeNewPrefixes() {
    if (data.first.id != -1) {
      data.first.prefix = '';
    }
    for (var i = 1; i < data.length; i++) {
      if (data[i - 1].order == data[i].order || data[i - 1].id == -1) {
        if (data[i].addedWithButton) {
          data[i].addedWithButton = !data[i].addedWithButton;
        }
        if (data[i - 1].prefix == '') {
          data[i].prefix = String.fromCharCode(a);
        } else {
          data[i].prefix =
              String.fromCharCode(data[i - 1].prefix.codeUnits.first + 1);
        }
      } else {
        data[i].prefix = '';
      }
    }
  }

  void processExercisePropetiesChoice(
      ExercisePropetiesChoice choice, int selectedIndex) {
    setState(() {
      data.insert(
          selectedIndex,
          Exercise(
            id: -1,
            order: data[selectedIndex].order,
            prefix: '',
          ));
      data[selectedIndex + 1].prefix = 'a';
      placeNewPrefixes();
    });
  }
}

List<Exercise> getExercisesFromJson(List<Map<String, dynamic>> json) {
  List<Exercise> result = [];
  for (var item in json) {
    var exercise = Exercise.fromJson(item);
    if (exercise.prefix == 'a') {
      result.add(Exercise(id: -1, order: exercise.order, prefix: ''));
    }
    result.add(exercise);
  }
  return result;
}

class Exercise {
  int id;
  int order;
  String prefix;
  bool addedWithButton;
  Exercise({
    required this.id,
    required this.order,
    required this.prefix,
    this.addedWithButton = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['order'] == null) {
      throw Exception('Wrong JSON');
    }
    return Exercise(
      id: json['id'],
      order: json['order'],
      prefix: json['order_prefix'] ?? '',
    );
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'order': order,
        'order_prefix': prefix,
      };
}

enum ExercisePropetiesChoice {
  addGroup,
}
