import 'package:flutter/material.dart';
import 'package:frappe_app/screens/activate_modules.dart';
import 'package:frappe_app/screens/no_internet.dart';
import 'package:frappe_app/widgets/frappe_button.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../config/palette.dart';
import '../utils/backend_service.dart';
import '../utils/enums.dart';
import '../utils/helpers.dart';
import '../widgets/card_list_tile.dart';

class DoctypeView extends StatefulWidget {
  final String module;

  DoctypeView(this.module);

  @override
  _DoctypeViewState createState() => _DoctypeViewState();
}

class _DoctypeViewState extends State<DoctypeView> {
  BackendService backendService;
  bool offline = false;

  @override
  void initState() {
    backendService = BackendService();

    super.initState();
  }

  Future _getData() {
    var connectionStatus = Provider.of<ConnectivityStatus>(
      context,
    );

    if (connectionStatus == ConnectivityStatus.offline) {
      offline = true;
      return Future.delayed(Duration(seconds: 1),
          () => getCache('${widget.module}Doctypes')["data"]);
    } else {
      offline = false;
      return backendService.getDesktopPage(widget.module, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgColor,
      appBar: AppBar(
        elevation: 0.6,
        title: Text(widget.module),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder(
          future: _getData(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var doctypesWidget = getActivatedDoctypes(
                snapshot.data,
                widget.module,
              );

              if (doctypesWidget.isEmpty) {
                return Container(
                  color: Colors.white,
                  height: double.infinity,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'No Doctypes are yet Activated or you dont have permission',
                      ),
                      FrappeFlatButton(
                        onPressed: () async {
                          var nav = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return ActivateModules();
                              },
                            ),
                          );

                          if (nav) {
                            setState(() {});
                          }
                        },
                        title: 'Activate Doctypes',
                        buttonType: ButtonType.primary,
                      )
                    ],
                  ),
                );
              }
              doctypesWidget = doctypesWidget.map<Widget>((m) {
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 10.0,
                    right: 10.0,
                    top: 8.0,
                  ),
                  child: CardListTile(
                    title: Text(m["label"]),
                    onTap: () async {
                      var response = await processData(
                        doctype: m["name"],
                        context: context,
                        offline: offline,
                      );

                      if (response["success"] == false) {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return NoInternet();
                            },
                          ),
                        );
                      } else {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return Router(
                                doctype: m["name"],
                                viewType: ViewType.list,
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList();
              return ListView(
                children: doctypesWidget,
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }
}
