import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '/utils.dart';
import '/app_constants.dart';
import '/models/device.dart';

class ProgramScaffold extends StatelessWidget {
  final Widget body;

  const ProgramScaffold({required this.body, super.key});

  @override
  Scaffold build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DeviceModel>(builder: (context, device, child) {
          return Row(children: [
            GestureDetector(
              onTap: () => {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const Dialog.fullscreen(
                      child: ProgramSelection(),
                    );
                  },
                )
              },
              child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                  child: Text(Utils.getProgramNoString(device.programNo),
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge!
                          .copyWith())),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog.fullscreen(
                        child: ProgramSelection(
                            bank: ((device.programNo ~/ 8) * 2) + 1),
                      );
                    },
                  );
                },
                child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
                    color: Theme.of(context).appBarTheme.backgroundColor,
                    child: Row(children: [
                      Text('${device.programName} [ S${device.scene + 1} ]')
                    ])),
              ),
            ),
          ]);
        }),
        actions: [
          Builder(builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: const Icon(Icons.menu),
            );
          }),
        ],
      ),
      endDrawer: Drawer(
        child: NavigationMenu(),
      ),
      endDrawerEnableOpenDragGesture: false,
      body: body,
    );
  }
}

class ProgramSelection extends StatefulWidget {
  final int bank;
  const ProgramSelection({this.bank = 0, super.key});

  @override
  State<ProgramSelection> createState() => ProgramSelectionState();
}

class ProgramSelectionState extends State<ProgramSelection> {
  int _bank = 0;

  void setBank(int bank) {
    setState(() {
      _bank = bank;
    });
  }

  @override
  void initState() {
    super.initState();
    _bank = widget.bank;
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle;
    List<Widget> content;

    if (_bank == 0) {
      List<Widget> bankButtons = [];
      int bank = 1;
      for (int row = 0; row < 4; row++) {
        List<Widget> rowWidgets = [];
        for (int col = 0; col < 4; col++) {
          rowWidgets.add(BankSelectionButton(bank, setBank));
          bank += 2;
        }

        bankButtons.add(Expanded(child: Row(children: rowWidgets)));
      }

      headerTitle = 'Select Bank';
      content = bankButtons;
    } else {
      List<Widget> programButtons = [];
      int programNo = (_bank - 1) * 4;
      for (int row = 0; row < 2; row++) {
        List<Widget> rowWidgets = [];
        for (int col = 0; col < 4; col++) {
          rowWidgets.add(ProgramSelectionButton(programNo));
          programNo++;
        }

        programButtons.add(Expanded(child: Row(children: rowWidgets)));
      }

      headerTitle = 'Select Program';
      content = programButtons;
    }

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(headerTitle,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
            child: Container(
          padding: const EdgeInsets.all(5),
          child: Column(children: content),
        )),
      ],
    );
  }
}

class BankSelectionButton extends StatelessWidget {
  final int bank;
  final Function setBank;

  const BankSelectionButton(this.bank, this.setBank, {super.key});

  String get bankString {
    return '$bank - ${bank + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: GestureDetector(
      onTap: () {
        setBank(bank);
      },
      child: Consumer<DeviceModel>(
        builder: (context, device, child) {
          final bool isCurrentBank =
              ((device.programNo ~/ 8) * 2) == (bank - 1);
          return Container(
            decoration: BoxDecoration(
              color: isCurrentBank
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(5),
            child: Center(
                child: Text(
              bankString,
              style: Theme.of(context).textTheme.titleLarge,
            )),
          );
        },
      ),
    ));
  }
}

class ProgramSelectionButton extends StatelessWidget {
  final int programNo;

  const ProgramSelectionButton(this.programNo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<DeviceModel>(builder: (context, device, child) {
        return GestureDetector(
          onTap: () {
            device.changeProgram(programNo);
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: programNo == device.programNo
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(5),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                  flex: 1,
                  child: Container(
                      alignment: Alignment.topCenter,
                      child: Text(
                        Utils.getProgramNoString(programNo),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ))),
              Expanded(
                  flex: 2,
                  child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        device.getProgramName(programNo),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(height: 0.9),
                        textAlign: TextAlign.center,
                      ))),
            ]),
          ),
        );
      }),
    );
  }
}

class NavigationMenu extends StatelessWidget {
  NavigationMenu({super.key});

  final _routeMenu = [
    RouteMenuItem('Stomp', '/stomp', Icons.grid_view),
    // RouteMenuItem('Bank', '/bank', Icons.pin),
    RouteMenuItem('Device Settings', '/device', Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    String routePath = '';
    var route = ModalRoute.of(context);
    if (route != null) {
      routePath = route.settings.name!;
    }

    final List<Widget> listChildren = [];
    listChildren.add(SizedBox(
      height: 130,
      child: DrawerHeader(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.appName,
                style: Theme.of(context).textTheme.titleLarge),
            Text(AppConstants.version),
          ],
        ),
      ),
    ));

    for (var menuItem in _routeMenu) {
      listChildren.add(ListTile(
        leading: Icon(menuItem.icon),
        title: Text(menuItem.name),
        selected: menuItem.route == routePath,
        selectedColor: Theme.of(context).textTheme.bodyMedium?.color,
        onTap: () {
          context.go(menuItem.route);
        },
      ));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: listChildren,
    );
  }
}

class RouteMenuItem {
  final String name;
  final String route;
  final IconData icon;

  RouteMenuItem(this.name, this.route, this.icon);
}
