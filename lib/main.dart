import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:imei_plugin/imei_plugin.dart';

const kAndroidUserAgent =
    'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Mobile Safari/537.36';

String selectedUrl = 'https://imei.kemenperin.go.id/';

bool hasChecked = false;
String curImei = "";



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (_) => MyHomePage(title: 'Eduprog Imei Validator'),
        '/widget': (_) {
          return WebviewScaffold(
            url: selectedUrl,
            mediaPlaybackRequiresUserGesture: false,
            appBar: AppBar(
              title: const Text('Imei Validator via Kemenperin'),
            ),
            withZoom: true,
            withLocalStorage: true,
            hidden: true,
            ignoreSSLErrors: true,
            initialChild: Container(
              color: Colors.grey.withOpacity(0.5),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(width: 10,),
                    Text('Menunggu...', style: TextStyle(fontWeight: FontWeight.bold),),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              child:  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    
                    child: FlatButton.icon(onPressed: (){
                      hasChecked = false;
                      flutterWebViewPlugin.reload();

                    }, icon: Icon(Icons.refresh), label: Text("Try Again")),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          width: 2,
                          color: Colors.white.withOpacity(0.5)
                      ),
                    ),
                    margin: EdgeInsets.all(5),
                  )

                ],
              ),
            ),
          );
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {

  MyHomePage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  String imei = "000000000000000";
  StreamSubscription _onDestroy;
  StreamSubscription<WebViewStateChanged> _onStateChanged;
  StreamSubscription<WebViewHttpError> _onHttpError;


  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> initPlatformState() async {
    String platformImei;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformImei = await ImeiPlugin.getImei( shouldShowRequestPermissionRationale: false );
    } on PlatformException {
      platformImei = 'Failed.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      imei = platformImei;
      curImei = imei;
    });
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    flutterWebViewPlugin.close();

    // Add a listener to on destroy WebView, so you can make came actions.
    _onDestroy = flutterWebViewPlugin.onDestroy.listen((_) {
      if (mounted) {
        _scaffoldKey.currentState.showSnackBar(
            const SnackBar(content: const Text('Webview Destroyed')));
      }
    });

    _onStateChanged =
        flutterWebViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
          if (mounted) {
            print('onStateChanged: ${state.type} ${state.url}');
            if (state.type == WebViewState.finishLoad){
              Future.delayed(Duration(seconds: 2), (){
                if (hasChecked == false && curImei != "") {
                  hasChecked = true;
                  flutterWebViewPlugin.evalJavascript(
                      "\$('input[name=\"imei\"]').val('$curImei')").then((
                      jsResult) {
                    print(jsResult);
                    if (jsResult != null && jsResult != "") {
                      var oJS = json.decode(jsResult);
                      if (oJS != null && oJS["length"] > 0) {
                        flutterWebViewPlugin.evalJavascript(
                            "\$('.btn').click()");
                      } else {
                        flutterWebViewPlugin.evalJavascript(
                            "Can't set imei number to web, try again.");
                      }
                    } else {
                      flutterWebViewPlugin.evalJavascript(
                          "Can't set imei number to web, try again.");
                    }
                  });
                }
              });
            }
          }
        });

    _onHttpError =
        flutterWebViewPlugin.onHttpError.listen((WebViewHttpError error) {
          if (mounted) {
            print('onHttpError: ${error.code} ${error.url}');
          }
        });
  }

  @override
  void dispose() {
    _onDestroy.cancel();
    _onStateChanged.cancel();
    _onHttpError.cancel();

    flutterWebViewPlugin.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double h = size.height;
    double w = size.width;
    return Scaffold(
      key: _scaffoldKey,
//      appBar: AppBar(
//        title: const Text('Eduprog Imei Validator'),
//      ),
      body: SafeArea(
        child: Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.blue.withOpacity(1.0), Colors.blue.withOpacity(0.7)])),
          child: Column(
            children: [
              Container(
                height: 150,
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 100,
                      width: 200,
                      child: FittedBox(
                        child: Image.asset('assets/logo-eduprog.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top:5),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      height: 40,
                      child: Text("Imei Validator", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromRGBO(20, 20, 10, 1.0)),),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 10.0,
                          ),
                        ],
                      )
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        child: Text("Your Device IMEI",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange
                          ),
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                          alignment: Alignment.center,
                          child: Text("$imei", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Color.fromRGBO(50, 50, 50, 1.0)),),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.white.withOpacity(0.9),
                                blurRadius: 10.0,
                              ),
                            ],
                          )
                      )


                    ],
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(left: 20),
                height: 150,
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(5),
                          child: FlatButton.icon(onPressed: () async {
                            imei = "";
                            setState(() {

                            });

                            imei = await ImeiPlugin.getImei( shouldShowRequestPermissionRationale: false );
                            curImei = imei;
                            setState(() {

                            });

                          }, icon: Icon(Icons.refresh, color: Colors.grey, size: 22,), label: Text("Reload Imei", style: TextStyle(color: Colors.black.withOpacity(0.9), fontSize: 16),) )
                          ,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 2,
                              color: Colors.white.withOpacity(0.8)
                            ),


                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          padding: EdgeInsets.all(5),
                          child: FlatButton.icon(onPressed: (){
                            if (imei == null || imei == ""){
                              _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text("Imei not found."),));
                            }else {
                              hasChecked = false;
                              curImei = imei;
                              Navigator.of(context).pushNamed("/widget");
                            }

                          }, icon: Icon(Icons.check, color: Colors.redAccent, size: 22,), label: Text("Validate Imei", style: TextStyle(color: Colors.black.withOpacity(0.9), fontSize: 16),) )
                          ,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                width: 2,
                                color: Colors.white.withOpacity(0.8)
                            ),


                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Center(child: Text("www.eduprog.net", style: TextStyle(color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold, fontSize: 15),),)
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}