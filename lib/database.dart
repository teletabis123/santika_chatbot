import 'dart:async';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:santika_chatbot_v2/ChatLog.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper{

  static Database _db;

  Future<Database> get db async {
    if(_db != null)
      return _db;
    _db = await initDb();
    return _db;
  }

  //Creating a database with name test.dn in your directory
  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "chatLog.db");
    print("Database created");
    var theDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return theDb;
  }

  // Creating a table name Employee with fields
  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute(
        "CREATE TABLE ChatLog(who INTEGER, message TEXT, time TIMESTAMP)");
    print("Created tables");
  }

  // Retrieving employees from Employee Tables
//  Future<List<Employee>> getEmployees() async {
//    var dbClient = await db;
//    List<Map> list = await dbClient.rawQuery('SELECT * FROM Employee');
//    List<Employee> employees = new List();
//    for (int i = 0; i < list.length; i++) {
//      employees.add(new Employee(list[i]["firstname"], list[i]["lastname"], list[i]["mobileno"], list[i]["emailid"]));
//    }
//    print(employees.length);
//    return employees;
//  }
  
//  Future<List<String>> getMessage() async{
//    var dbClient = await db;
//    List<Map> chatList = await dbClient.rawQuery('SELECT * FROM ChatLog WHERE time LIKE "$_makeTimestampWithoutHour()"');
//
//    print('SELECT * FROM ChatLog WHERE time LIKE "$_makeTimestampWithoutHour()"');
//
//    return null;
//  }

  Future<List<ChatLog>> getMessage() async{
    var dbClient = await db;
    String query = 'SELECT * FROM ChatLog WHERE time LIKE "' + _makeTimestampWithoutClock() + '%";';
    List<Map> result = await dbClient.rawQuery(query);
    List<ChatLog> chatLogs = new List();

    for(int i=0; i<result.length; i++){
      chatLogs.add(new ChatLog(result[i]['who'], result[i]['message']));
    }

    print("Print in DB: " + chatLogs.length.toString());

    //chatList.forEach((row) => print(row));

    return chatLogs;
  }

  void saveChatLog(int who, String message, String time) async {
    var dbClient = await db;
    await dbClient.transaction((txn) async {
      return await txn.rawInsert(
          'INSERT INTO ChatLog (who, message, time) VALUES($who, "$message", "$time");'
      );
    });
    print("\nINSERT INTO ChatLog VALUES(\"$message\", \"$time\");");
    print("This chat is successfully added to DB");
  }

  String _makeTimestampWithoutClock(){
//    String day = DateTime.now().day < 10 ? "0" + DateTime.now().day.toString() : DateTime.now().day.toString();
//    String month = DateTime.now().month < 10 ? "0" + DateTime.now().month.toString() : DateTime.now().month.toString();
    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();

    print("Timestamp to be checked in db: " + year.toString() + "-" + month.toString() + "-" + day.toString());

    String timestamp = year + "-" + month + "-" + day;

    return timestamp;
  }
}
