import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _controlador = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List compras = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        compras = json.decode(data);
        _refresh();
      });
    });
  }

  void _addCompras() {
    setState(() {
      Map<String, dynamic> newCompras = Map();
      newCompras["title"] = _controlador.text;
      _controlador.text = "";
      newCompras["ok"] = false;
      compras.add(newCompras);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    setState(() {
      compras.sort((a, b) {
        if (a["ok"] == true && b["ok"] == false)
          return 1;
        else if (a["ok"] == false && b["ok"] == true)
          return -1;
        else
          return 0;
      });
      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista de Compras"),
          backgroundColor: Colors.green,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
                padding: EdgeInsets.fromLTRB(15, 10, 5, 10),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: <Widget>[
                      Theme(
                          data: ThemeData(
                              primaryColor: Colors.green,
                              hintColor: Colors.green),
                          child: Expanded(
                              child: TextFormField(
                                  controller: _controlador,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return "Insira um item";
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.green),
                                          borderRadius:
                                              BorderRadius.circular(100)),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(100)),
                                      labelText: "Novo item",
                                      hintText: "Insira um item",
                                      hintStyle: TextStyle(color: Colors.grey),
                                      labelStyle:
                                          TextStyle(color: Colors.green),
                                      suffixIcon: IconButton(
                                        onPressed: () => _controlador.clear(),
                                        icon: Icon(Icons.clear,
                                            color: Colors.grey),
                                      ))))),
                      Padding(padding: EdgeInsets.only(right: 6)),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: Colors.green,
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(12)),
                          child: Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              _addCompras();
                            }
                          }),
                    ],
                  ),
                )),
            Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 5),
                  itemCount: compras.length,
                  itemBuilder: buildItem),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: Icon(Icons.add),
          label: Text("Nova lista"),
          onPressed: () {
            compras.clear();
            _saveData();
          },
          backgroundColor: Colors.green,
        ),
        resizeToAvoidBottomInset: false);
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: ListTile(
        leading: Icon(
            compras[index]["ok"] == true
                ? Icons.shopping_cart
                : Icons.shopping_cart_outlined,
            size: 25,
            color: compras[index]["ok"] == true ? Colors.green : Colors.red),
        title: Text(
          compras[index]["title"],
          style: GoogleFonts.itim(
              fontSize: 22,
              decoration: compras[index]["ok"] == true
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: Colors.green),
        ),
        onTap: () {
          setState(() {
            if (compras[index]["ok"] == false) {
              compras[index]["ok"] = true;
              _saveData();
            } else if (compras[index]["ok"] == true) {
              compras[index]["ok"] = false;
              _saveData();
            }
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(compras[index]);
          _lastRemovedPos = index;
          compras.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text(
              "Item \'${_lastRemoved["title"]}\' removido",
              style: TextStyle(fontSize: 15),
            ),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    compras.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );

          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(compras);
    _refresh();

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
