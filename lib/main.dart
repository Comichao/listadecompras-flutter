import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:share/share.dart';

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
        _sort();
      });
    });
  }

  void _addCompras() {
    setState(() {
      Map<String, dynamic> newCompras = Map();
      newCompras["title"] = _controlador.text;
      newCompras["ok"] = false;
      _controlador.text = "";
      compras.add(newCompras);
      _saveData();
    });
  }

  void _sort() {
    setState(() {
      compras.sort((a, b) {
        if (a["ok"] == true && b["ok"] == false)
          return 1;
        else if (a["ok"] == false && b["ok"] == true)
          return -1;
        else
          return 0;
      });
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
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.share),
                onPressed: () {
                  Share.share('*LISTA DE COMPRAS* \n${_shareLista()}');
                })
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
          child: Column(
            children: <Widget>[
              Container(
                  padding: EdgeInsets.fromLTRB(15, 10, 5, 0),
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
                                      if (value == null || value.isEmpty) {
                                        return "Insira um item";
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                        helperText: ' ',
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
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        labelStyle:
                                            TextStyle(color: Colors.green),
                                        suffixIcon: IconButton(
                                          onPressed: () => _controlador.clear(),
                                          icon: Icon(Icons.clear,
                                              color: Colors.grey),
                                        ))))),
                        Padding(padding: EdgeInsets.only(right: 6)),
                        Column(children: [
                          ElevatedButton(
                            child:
                                Icon(Icons.add, color: Colors.white, size: 28),
                            style: ElevatedButton.styleFrom(
                                primary: Colors.green,
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(12)),
                            onPressed: () {
                              if (_formKey.currentState.validate()) {
                                _addCompras();
                              }
                            },
                          ),
                          SizedBox(
                            height: 22,
                          )
                        ])
                      ],
                    ),
                  )),
              Expanded(
                child: ListView.builder(
                    itemCount: compras.length, itemBuilder: buildItem),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: Icon(Icons.add),
          label: Text("Nova lista"),
          onPressed: () {
            setState(() {
              _showAlertDialog(context);
              _saveData();
            });
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
            } else {
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

  _shareLista() {
    String listaShare = '';
    for (var i = 0; i < compras.length; i++) {
      listaShare += '- ${compras[i]["title"]}';
      listaShare += '\n';
    }
    return listaShare;
  }

  _showAlertDialog(BuildContext context) {
    Widget _sim = TextButton(
      onPressed: () {
        compras.clear();
        Navigator.pop(context);
        _saveData();
      },
      child:
          Text("Sim", style: TextStyle(color: Colors.teal[800], fontSize: 17)),
    );
    Widget _nao = TextButton(
      onPressed: () {
        Navigator.pop(context);
        FocusManager.instance.primaryFocus.unfocus();
      },
      child:
          Text("Não", style: TextStyle(color: Colors.teal[800], fontSize: 17)),
    );

    AlertDialog _alert = AlertDialog(
      title: Text(
        "Nova lista",
        style: TextStyle(fontSize: 22),
      ),
      content: Text("Deseja limpar a lista atual e criar uma nova?",
          style: TextStyle(fontSize: 17)),
      actions: [_nao, _sim],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return _alert;
        },
        barrierDismissible: true);
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(compras);
    _sort();

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
