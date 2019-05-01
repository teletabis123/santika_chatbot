import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:santika_chatbot_v2/ChatLog.dart';
import 'dart:async';
import 'dart:convert';

import 'package:santika_chatbot_v2/database.dart';

void main() => runApp(new ChatBot());

class ChatBot extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Santika Helper',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: new ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget{
  @override
  State createState() => new ChatScreenState();
}

Future<List<ChatLog>> fetchChatLogFromDB() async{
  var dbHelper = DBHelper();
  List<ChatLog> chatLogs = await dbHelper.getMessage();
  return chatLogs;
}

class ChatScreenState extends State<ChatScreen>{
  final TextEditingController _textController = new TextEditingController();

  final List<ChatMessage> _message = <ChatMessage>[];

  var dbAdapeter = new DBHelper();

  bool initialized = false;


  void _getInitData() async{
    List<ChatLog> chatLog = await fetchChatLogFromDB();
    print("Print in State: " + chatLog.length.toString());
    int length = chatLog.length;
    print(chatLog);
    if(length > 0){
      for(int i=0; i<length; i++){
        ChatMessage message = new ChatMessage(text: chatLog[i].message, who: i%2==0? 0 : 1,);
        setState(() {
          _message.insert(0, message);
        });

      }
    }
  }

  Future<bool> _backButtonPressed(){
    print(initialized ? "Initialized" : "Not initialized");
    initialized = false;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {

    if(!initialized){
      _getInitData();
      initialized = true;
    }

    return WillPopScope(
      onWillPop: _backButtonPressed,
      child: new Scaffold(
        appBar: new AppBar(title: new Text("My Santika Chatroom"),),
        body: new Column(
          children: <Widget>[
            new Flexible(
              child: new ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) => _message[index],
                itemCount: _message.length,
              ),
            ),
            new Divider(height: 1.0,),
            new Container(
              decoration: new BoxDecoration(
                color: Theme.of(context).cardColor
              ),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer(){
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            new Flexible(
              child: new TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: new InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            new Container(
              //margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
                // What to do after send icon is pressed
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleSubmitted(String text){
    _textController.clear();

    ChatMessage message = new ChatMessage(text: text, who: 0,);
    _saveToDB(0, text);

    ChatMessage messageResponse;

    //String url = "https://staging-santika.oval.id/room-types/?hotel=98";
    //String url = "https://aiml-server-heroku.herokuapp.com/ketersediaan kamar deluxe pada tanggal 06-06-2019";
    String url = "https://aiml-server-heroku.herokuapp.com/";

    String mResponse = "";
    Future getAndParse(String param) async {
      List<dynamic> response = new List();
      url += param;
      print("Text        : " + text);
      print("Url         : " + url);
      print("Encoded Url : " + Uri.encodeFull(url));
      var res = await http.get(Uri.encodeFull(url), headers: {"Authentication": "Bearer329e2f262b9e03c89379284ca9735332fb151575"});

      print("Done waiting!");

      setState(() {
        var resBody = json.decode(res.body);
        print(resBody);

        print("Reformatting json result");

        response.add(resBody['ul']); //index 0 -> ul
        int ul = response[0];

        response.add(new List<dynamic>()); //index 1 -> il
        for(int i=0; i<=response[0]; i++){ //isi dari il
          response[1].add(resBody['il'][i]);
          print("il[$i]: " + response[1][i][i.toString()].toString());
          //access -> respose[1][i][i.toString()]
        }
        response.add(resBody['message']); //index 2 -> message
        print(response[2]);

        if(ul == 0){
          print("Message: " + response[2][0]["0"]);
          mResponse = response[2][0]["0"];
        }
        else if(ul == 1){
          List<String> messageResult = new List();
          for(int i=0; i<=response[1][1]['1']; i++){
            messageResult.add(response[2][ul][ul.toString()][i][i.toString()]);
            mResponse += (i>0? "- " : "") + messageResult[i] + "\n";
            print("Message result $i: " + messageResult[i]);
          }
        }
        else if(ul == 2){
          List<dynamic> messageResult = new List();

          messageResult.add(response[2][0]["0"]);
          print(messageResult[0]);

          //messageResult.add(detailMessage);
          mResponse += messageResult[0] + "\n";
          for(int i=1; i<=ul; i++){
            messageResult.add(new List<String>());
//            print("Current value of i: " + i.toString());
//            print("Child in index $i: " +  response[1][i][i.toString()].toString());

            for(int j=0; j<=response[1][i][i.toString()]; j++){
              //print(j);
              messageResult[i].add(response[2][i][i.toString()][j][j.toString()]);

              mResponse += (j>0? "- " : "") + messageResult[i][j] + ((j==response[1][i][i.toString()] && i==1) ? "\n\n" : "");
            }
            print(messageResult[i]);
          }

//          for(int i=1; i<=ul; i++){
//            for(int j=0; j<=response[1][i][i.toString()]; j++){
//              print(messageResult[i][j]);
//            }
//          }
        }

        messageResponse = new ChatMessage(text: mResponse, who: 1,);
        _saveToDB(1, mResponse);
        _message.insert(0, messageResponse);
      });
    }

    setState(() {
      _message.insert(0, message);
      getAndParse(text);
    });
  }
}

const String _name = "User"; //harusnya nama kita disini
const String _botName = "Chatbot"; //nama bot nya

class ChatMessage extends StatelessWidget{

  ChatMessage({this.text, this.who});
  final String text;
  final int who;

  @override
  Widget build(BuildContext context) {
    final c_width = MediaQuery.of(context).size.width*0.6;

    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      //width: MediaQuery.of(context).size.width*0.5,
      child: new Row(
        textDirection: who == 0 ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: c_width,
            padding: new EdgeInsets.all(10.0),
            decoration: new BoxDecoration(
              color: who == 1 ? Colors.white : Colors.grey,
              borderRadius: new BorderRadius.all(Radius.circular(5.0)),
            ),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //new Text(who == 1 ? _botName : _name, style: Theme.of(context).textTheme.subhead),
                new Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: new Text(text, style: TextStyle(fontSize: 15.0),),
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }
}

void _saveToDB(int who, String message){
  var dbHelper = new DBHelper();

  dbHelper.saveChatLog(who, message, _makeTimestamp());

}

String _makeTimestamp(){
  String day = DateTime.now().day.toString();
  String month = DateTime.now().month.toString();
  String year = DateTime.now().year.toString();
  String hour = DateTime.now().hour.toString();
  String minute = DateTime.now().minute.toString();
  String second = DateTime.now().second.toString();

  print("Timestamp to be inserted to db: " + year.toString() + "-" + month.toString() + "-" + day.toString()
      + " " + hour.toString() + ":" + minute.toString() + ":" + second.toString());

  String timestamp = year + "-" + month + "-" + day + " " +
      hour + ":" + minute + ":" + second;

  return timestamp;
}

//Old Code to reformatting json
//if(text.contains("ketersediaan") || text.contains("pengecekan")){
//var resCek = json.decode(res.body);
//mResponse = resCek["message"];
//}
//else{
//response.add(resBody["ul"]); //index 0
//response.add(resBody["il"]); //index 1
//response.add(resBody["message"]);//index 2
//response.add(resBody["header"]);
//
//int index = 0;
//print(response[0] == null ? "No ul tag in json" : "This type is " + response[0].runtimeType.toString() + " with value of " + response[0].toString());
//print(response[1] == null ? "No il tag in json" : "This type is " + response[1].runtimeType.toString() + ".");
//print(response[1][0][index.toString()] == null ? "There is no \"0\" in tag il" : response[1][0]["0"]); //tag il "0"
//print(response[2][0][index.toString()] != "" ? "There is no \"1\" in tag il" : response[1][1]["1"]); //tag il "1"
//print(response[2].runtimeType.toString());
//print(response[2][0][index.toString()] == "" ? "Index 0 kosong" : response[2][0]["0"]); //message "0"
//
//int indexMessageStart = response[1][0]["0"];
//int indexMessageEnd = response[2][0]["0"] == "" ? response[1][1]["1"] : response[1][0]["0"]; //kalo message[0] berisi, dia jd sm ky il "0"
//
//print(indexMessageStart.toString());
//print(indexMessageEnd.toString());
//
//if(indexMessageStart == indexMessageEnd){
//mResponse = response[2][0]["0"];
//_saveToDB(1, mResponse, DateTime.now());
//}
//else{
//print(indexMessageStart.toString());
//print(indexMessageEnd.toString());
//mResponse += response[3] + "\n";
//int i;
//for(i = indexMessageStart; i<=indexMessageEnd; i++){
//mResponse += " - " + response[2][1]["1"][i][i.toString()] + (i != indexMessageEnd ? "\n" : "");
//}
//_saveToDB(1, mResponse, DateTime.now());
////mResponse = ""; //sementara
//}
//}
//
//messageResponse = new ChatMessage(text: mResponse, who: 1,);
//
//_message.insert(0, messageResponse);