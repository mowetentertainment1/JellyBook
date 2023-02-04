import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:jellybook/screens/loginScreen.dart';
import 'package:isar/isar.dart';
import 'package:isar_flutter_libs/isar_flutter_libs.dart';
import 'package:jellybook/screens/offlineBookReader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jellybook/models/entry.dart';
import 'package:jellybook/models/folder.dart';
import 'package:jellybook/models/login.dart';
import 'package:logger/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // top bar always visible, bottom bar only visible when swiped up
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: [
    SystemUiOverlay.top,
  ]);

  //
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final isar = await Isar.open([EntrySchema, FolderSchema, LoginSchema]);

  Logger.level = Level.debug;
  var logger = Logger();

  if (kDebugMode) {
    try {
      // delete all entries in the database
      // get a list of all the entries ids
      var entries = await isar.entrys.where().findAll();
      var entryIds = entries.map((e) => e.isarId).toList();
      await isar.writeTxn(() async {
        isar.entrys.deleteAll(entryIds);
        logger.d("deleted ${entryIds.length} entries");
      });
      // delete all folders in the database
      // get a list of all the folders ids
      var folders = await isar.folders.where().findAll();
      var folderIds = folders.map((e) => e.isarId).toList();
      await isar.writeTxn(() async {
        isar.folders.deleteAll(folderIds);
        logger.d("deleted ${folderIds.length} folders");
      });
    } catch (e) {
      logger.e(e);
    }
    logger.d("cleared Isar boxes");
  }

  var logins = await isar.logins.where().findAll();
  if (logins.length != 0) {
    logger.d("login url: " + logins[0].serverUrl);
    logger.d("login username: " + logins[0].username);
    logger.d("login password: " + logins[0].password);
    runApp(MyApp(
        url: logins[0].serverUrl,
        username: logins[0].username,
        password: logins[0].password));
    logger.d("login found");
  }
}

class MyApp extends StatelessWidget {
  final String? url;
  final String? username;
  final String? password;

  const MyApp({Key? key, this.url, this.username, this.password})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JellyBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark(),
      home: FutureBuilder(
        future: Connectivity().checkConnectivity(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == ConnectivityResult.none) {
              return OfflineBookReader();
            } else {
              return LoginScreen(
                url: url,
                username: username,
                password: password,
              );
            }
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
