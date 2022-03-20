import 'package:flutter/material.dart';

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
    for (var element in inputData) {
      data.add(Exercise.fromJson(element));
    }
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                key: Key('$index'),
                children: [
                  data[index].prefix != ''
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
                          child: Text(
                              '${data[index].prefix}: упражнение №${data[index].id}'),
                        )
                      : Text(
                          '${data[index].order}: упражнение №${data[index].id}'),
                ],
              ),
            );
          },
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = data.removeAt(oldIndex);
              data.insert(newIndex, item);
            });
          },
        ));
  }
}

class Exercise {
  int id;
  int order;
  String prefix;
  Exercise({
    required this.id,
    required this.order,
    required this.prefix,
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

class ExerciseGroup {
  List<Exercise> exercises;
  ExerciseGroup({
    required this.exercises,
  });

  factory ExerciseGroup.fromJson(List<Map<String, dynamic>> json) =>
      ExerciseGroup(exercises: json.map((e) => Exercise.fromJson(e)).toList());

  bool isSingle() {
    return exercises.length > 1 || exercises.isEmpty ? false : true;
  }

  List<Map<String, dynamic>> toJson() =>
      exercises.map((e) => e.toJson()).toList();
}

List<ExerciseGroup> groupsFromJson(List<Map<String, dynamic>> inputList) {
  List<Exercise> rawExercise = [];
  List<ExerciseGroup> result = [];
  for (var element in inputList) {
    rawExercise.add(Exercise.fromJson(element));
  }
  int i = 0;
  while (i < rawExercise.length) {
    int lastExerciseIndex = rawExercise
        .lastIndexWhere((exercise) => exercise.order == rawExercise[i].order);
    if (lastExerciseIndex != i) {
      result.add(
          ExerciseGroup(exercises: rawExercise.sublist(i, lastExerciseIndex)));
      i = lastExerciseIndex + 1;
    } else {
      result.add(ExerciseGroup(exercises: [rawExercise[i]]));
      i++;
    }
  }
  return result;
}
