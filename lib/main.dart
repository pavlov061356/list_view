import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
  int _oldPos = 0;
  int _newPos = 0;
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
        floatingActionButton: FloatingActionButton(
          onPressed: writeData,
          child: const Icon(Icons.add),
        ),
        body: ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          itemCount: data.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
                key: Key('$index'),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    data[index].id == -1
                        ? Text('${data[index].order}:')
                        //Если начинается группа,
                        //то рисует её порядковый номер
                        : data[index].prefix != ''
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
                                child: Text(
                                    '${data[index].prefix}: упражнение №${data[index].id}'),
                                //Если является участником группы упражнений
                              )
                            : Text(
                                '${data[index].order}: упражнение №${data[index].id}'),
                    //Если является отдельным упражнением
                    data[index].id != -1 &&
                            data[index].prefix ==
                                '' // Определение отдельного упражнения
                        ? Padding(
                            padding: const EdgeInsets.only(right: 40),
                            child: PopupMenuButton<ExercisePropetiesChoice>(
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
                            ),
                          )
                        : Container()
                  ],
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ));
          },
          onReorder: (int oldIndex, int newIndex) {
            if (data[oldIndex].id != -1) {
              // Запрет переноса элементов, обозначающих начало группы
              if (!data[oldIndex].addedWithButton) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  _oldPos = oldIndex;
                  _newPos = newIndex;
                  _processExercise();
                });
              }
            }
          },
        ));
  }

  void writeData() async {
    var jsonDirectory = await getApplicationDocumentsDirectory();
    File outputFile = File(jsonDirectory.path + '/output.json');
    String json = exercisesToJson(data);
    print('Writing Json to file ${outputFile.path}');
    outputFile.writeAsStringSync(json);
    print(json);
  }

  void _processExercise() {
    var deletedEx = deleteMoved();
    insertMoved(deletedEx);
    placeNewPrefixes();
  }

  /// Удаляет перемещённое занятие, и удаляет группу, если занятие было единственным в группе
  /// Возвращает удалённый объект
  Exercise deleteMoved() {
    var obj = data.removeAt(_oldPos);
    if (obj.prefix == '') {
      //В том случае, если упражнение являлось самостоятельным, необходимо при
      //его удалении для всех следующих после него элементов уменьшить их порядковый
      // номер, далее он будет увеличен в зависимости от того, куда будет вставлен сам элемент
      for (var i = _oldPos; i < data.length; i++) {
        data[i].order--;
      }
    } else if (data.lastIndexWhere((element) => element.order == obj.order) -
            data.indexWhere(
                (element) => element.id == -1 && element.order == obj.order) <
        2) {
      // В том случае, если из группы с 2 элементами удаляется один из
      //элементов, группу надо удалить
      obj.prefix = '';

      int groupInd = data.indexWhere((element) =>
          element.id == -1 &&
          element.order == obj.order &&
          element.addedWithButton == false);
      data.removeAt(groupInd);
      data[groupInd].prefix = '';
      if (groupInd < _newPos) {
        _newPos--;
      }
    }
    return obj;
  }

  /// Вставляет занятие в список, и расставляет порядкоые номера в правильной
  /// последовательности
  void insertMoved(Exercise moved) {
    data.insert(_newPos, moved);
    if (_newPos == 0) {
      // Вставка в самую первую позицию всегда ставит порядковый
      //номер на единицу, и для всех последующих упражнений увеличивет их порядковый номер
      data[_newPos].order = 1;
      for (var i = _newPos + 1; i < data.length; i++) {
        data[i].order++;
      }
    } else if (_newPos + 1 == data.length) {
      // Вставка в конец ставит порядковый
      //номер на единицу больше предыдущего
      data[_newPos].order = data[_newPos - 1].order + 1;
    } else if (data[_newPos + 1].prefix == '' &&
            data[_newPos - 1].prefix == '' ||
        data[_newPos + 1].prefix == '' && data[_newPos - 1].prefix != '') {
      // Вставка занятия не в группу, и увеличение порядкового номера
      // у всех последующих элементов
      data[_newPos].order = data[_newPos + 1].order;
      for (var i = _newPos + 1; i < data.length; i++) {
        data[i].order++;
      }
    } else if ((data[_newPos + 1].prefix != '')) {
      // Вставка элемента в группу, и установка его порядкового элемента
      data[_newPos].order = data[_newPos - 1].order;
    }
  }

  /// Расставляет префиксы в согласовании с расставленными порядковыми именами
  void placeNewPrefixes() {
    data.first.prefix = ''; // Певрый элемент всегда с пустым префиксом
    for (var i = 1; i < data.length; i++) {
      if (data[i - 1].order == data[i].order || data[i - 1].id == -1) {
        // Группа упражнений
        if (data[i].addedWithButton) {
          // Снятие запрета на удаление группы из 1 элемента добавленного
          // с помощью кнопки
          data[i].addedWithButton = !data[i].addedWithButton;
        }
        if (data[i - 1].prefix == '') {
          // Первый элемент группы всегда помечается буквой 'a'
          data[i].prefix = String.fromCharCode(a);
        } else {
          // Далее все последующие префиксы инкрементируются относительно предыдущего
          data[i].prefix =
              String.fromCharCode(data[i - 1].prefix.codeUnits.first + 1);
        }
      } else {
        // Отдельным упражнениям присваивается пустой префикс
        data[i].prefix = '';
      }
    }
  }

  /// Callback, который вызывается при выборе выпадающего списка у самостоятельного
  /// упражнения
  ///
  /// [choice] : enum, который получается при выборе вариантов из списка
  ///
  /// [selectedIndex] : индекс упражнения, для которого выбирается создание группы
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
      if (selectedIndex + 2 < data.length) {
        if (data[selectedIndex + 2].prefix == '' &&
            data[selectedIndex + 2].id != -1) {
          for (var i = selectedIndex + 2; i < data.length; i++) {
            data[i].order--;
          }
        }
      }
      placeNewPrefixes();
    });
  }
}

/// Функция, которая парсит JSON, с сервера и возвращает список из [Exercise]
/// который дальше используется для отрисовки списка

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

/// Переводит список занятий в готорый Json
String exercisesToJson(List<Exercise> input) {
  List<Map<String, dynamic>> outputJson = [];
  for (var item in input) {
    if (item.id != -1) {
      if (item.prefix != '') {
        int lastIndex =
            input.lastIndexWhere((element) => element.order == item.order);
        int firstIndex =
            input.indexWhere((element) => element.order == item.order);
        if (firstIndex + 1 != lastIndex) {
          outputJson.add(item.toJson());
        } else {
          outputJson.add(item.copyWithoutPrefix().toJson());
        }
      } else {
        outputJson.add(item.toJson());
      }
    }
  }
  return json.encode(outputJson);
}

/// Класс занятия,
///  - [id] идентификатор занятия
///  - [order] порядковый номер занятия
///  - [prefix] префикс занятия в группе
///  - [addedWithButton] параметр, который помечает группу созданной с помощью
///  кнопки, чтобы не удалять автоматически группу с 1 элементом
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

  Exercise copyWithoutPrefix() {
    return Exercise(
      id: id,
      order: order,
      prefix: '',
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
