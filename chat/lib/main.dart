import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = TextEditingController();
  final db = mongo.Db('mongodb://localhost:27017/test');
  mongo.DbCollection? messagesCollection;

  @override
  void initState() {
    super.initState();
    initDb();
  }

  void initDb() async {
    if (db != null) {
      await db.open();
      messagesCollection = db.collection('messages');
    }
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  void saveMessage(String text) async {
    print('saveMessage() start');
    if (messagesCollection != null) {
      await messagesCollection?.insertOne({'text': text});
    } else {
      print('messagesCollection is null');
    }
    print('saveMessage() end');
  }
  
  
  void onSubmitted(String text) {
    print('onSubmitted() text: $text');
    print('onSubmitted() messagesCollection: $messagesCollection');
    if (text.isNotEmpty && messagesCollection != null) {
      saveMessage(text);
      controller.clear();
    }
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: messagesCollection != null
                  ? messagesCollection!
                      .find()
                      .toList()
                      .timeout(Duration(seconds: 5))
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData && snapshot.data != null) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var message = snapshot.data![index];
                      if (message != null &&
                          message.containsKey('text') &&
                          message['text'] != null) {
                        return ListTile(
                          title: Text(message['text'].toString()),
                        );
                      } else {
                        return ListTile(
                          title: Text('Mensaje no válido'),
                        );
                      }
                    },
                  );
                } else {
                  return Text('No se encontraron mensajes');
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Escribe un mensaje',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty && messagesCollection != null) {
                  saveMessage(text);
                  controller.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
