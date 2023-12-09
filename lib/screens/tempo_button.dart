import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/app_constants.dart';
import '/utils.dart';
import '/models/device.dart';

class TempoButton extends StatelessWidget {
  const TempoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceModel>(builder: (context, device, child) {
      Color backgroundColor = Theme.of(context).colorScheme.background;
      Color blockColor = Colors.lightBlueAccent;
      return GestureDetector(
          onTap: () {
            device.tapTempo();
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: TempoEditDialog(
                      tempo: device.tempo,
                      showTempoInMillisec: device.showTempoInMillisec,
                      globalTempo: device.globalTempo),
                );
              },
            );
          },
          child: Container(
              padding: const EdgeInsets.all(5),
              child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(
                      color: blockColor,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Column(children: [
                    Expanded(
                        child: Container(
                      alignment: Alignment.topRight,
                      child: Icon(Icons.language,
                          size: Theme.of(context).textTheme.bodyLarge?.fontSize,
                          color: device.globalTempo
                              ? blockColor
                              : Theme.of(context).scaffoldBackgroundColor),
                    )),
                    Expanded(
                        flex: 4,
                        child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              device.tempoForDisplay,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    color: blockColor,
                                  ),
                            ))),
                    Expanded(
                        flex: 2,
                        child: Container(
                            alignment: Alignment.topCenter,
                            child: Text(
                                device.showTempoInMillisec ? 'ms' : 'BPM',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      color: blockColor,
                                    ))))
                  ])))));
    });
  }
}

class TempoEditDialog extends StatefulWidget {
  final int tempo;
  final bool showTempoInMillisec;
  final bool globalTempo;

  const TempoEditDialog(
      {this.tempo = 40,
      this.showTempoInMillisec = false,
      this.globalTempo = false,
      super.key});

  @override
  State<TempoEditDialog> createState() => TempoEditState();
}

class TempoEditState extends State<TempoEditDialog> {
  bool _dirty = false;
  List<String> _tempoUnderEdit = [];

  bool _showTempoInMillisec = false;
  bool _globalTempo = false;

  @override
  void initState() {
    super.initState();
    _showTempoInMillisec = widget.showTempoInMillisec;
    _globalTempo = widget.globalTempo;

    if (_showTempoInMillisec) {
      _tempoUnderEdit = Utils.bpmToMs(widget.tempo).toString().split('');
    } else {
      _tempoUnderEdit = widget.tempo.toString().split('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.all(5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              child:
                  Text('Tempo', style: Theme.of(context).textTheme.titleLarge),
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
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        _tempoUnderEdit.join(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayLarge,
                                      ),
                                    ),
                                  ),
                                  ToggleButtons(
                                    isSelected: [
                                      !_showTempoInMillisec,
                                      _showTempoInMillisec
                                    ],
                                    onPressed: (int index) {
                                      setState(() {
                                        if ((index == 0) &&
                                            _showTempoInMillisec) {
                                          int tempoBPM = Utils.msToBpm(
                                              int.parse(
                                                  _tempoUnderEdit.join()));
                                          _tempoUnderEdit =
                                              tempoBPM.toString().split('');
                                        } else if ((index == 1) &&
                                            !_showTempoInMillisec) {
                                          int tempoMS = Utils.bpmToMs(int.parse(
                                              _tempoUnderEdit.join('')));
                                          _tempoUnderEdit =
                                              tempoMS.toString().split('');
                                        }
                                        _showTempoInMillisec = index == 1;
                                      });
                                    },
                                    children: const [Text('BPM'), Text('ms')],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Global Tempo',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  SizedBox(
                                      width: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.fontSize ??
                                          16),
                                  Switch(
                                    onChanged: (value) {
                                      setState(() {
                                        _globalTempo = value;
                                      });
                                    },
                                    value: _globalTempo,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (_tempoUnderEdit.isNotEmpty) {
                                _tempoUnderEdit.clear();
                              }
                            });
                          },
                          style: Theme.of(context)
                              .elevatedButtonTheme
                              .style
                              ?.copyWith(
                                backgroundColor: MaterialStatePropertyAll(
                                    _tempoUnderEdit.isEmpty
                                        ? Colors.grey
                                        : Colors.redAccent),
                              ),
                          child: const Text('Clear'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        child: Consumer<DeviceModel>(
                            builder: (context, device, child) {
                          return ElevatedButton(
                            onPressed: () {
                              if (_tempoUnderEdit.isNotEmpty) {
                                setState(() {
                                  if (_dirty) {
                                    int tempoBPM;
                                    if (_showTempoInMillisec) {
                                      int tempoMS =
                                          int.parse(_tempoUnderEdit.join());
                                      if (tempoMS > AppConstants.minTempoMS) {
                                        tempoMS = AppConstants.minTempoMS;
                                      } else if (tempoMS <
                                          AppConstants.maxTempoMS) {
                                        tempoMS = AppConstants.maxTempoMS;
                                      }

                                      tempoBPM = Utils.msToBpm(tempoMS);
                                    } else {
                                      tempoBPM =
                                          int.parse(_tempoUnderEdit.join());
                                      if (tempoBPM < AppConstants.minTempoBPM) {
                                        tempoBPM = AppConstants.minTempoBPM;
                                      } else if (tempoBPM >
                                          AppConstants.maxTempoBPM) {
                                        tempoBPM = AppConstants.maxTempoBPM;
                                      }
                                    }

                                    device.updateAllTempoData(tempoBPM,
                                        _showTempoInMillisec, _globalTempo);
                                  } else {
                                    device.updateTempoFlags(
                                        _showTempoInMillisec, _globalTempo);
                                  }
                                });
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              }
                            },
                            style: _tempoUnderEdit.isEmpty
                                ? Theme.of(context)
                                    .elevatedButtonTheme
                                    .style
                                    ?.copyWith(
                                      backgroundColor:
                                          const MaterialStatePropertyAll(
                                              Colors.grey),
                                    )
                                : Theme.of(context).elevatedButtonTheme.style,
                            child: const Text('Confirm'),
                          );
                        }),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              _TempoNumericButton('7', numericButtonCallback),
                        ),
                        Expanded(
                          child:
                              _TempoNumericButton('8', numericButtonCallback),
                        ),
                        Expanded(
                          child:
                              _TempoNumericButton('9', numericButtonCallback),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              _TempoNumericButton('4', numericButtonCallback),
                        ),
                        Expanded(
                          child:
                              _TempoNumericButton('5', numericButtonCallback),
                        ),
                        Expanded(
                          child:
                              _TempoNumericButton('6', numericButtonCallback),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              _TempoNumericButton('1', numericButtonCallback),
                        ),
                        Expanded(
                          child:
                              _TempoNumericButton('2', numericButtonCallback),
                        ),
                        Expanded(
                          child:
                              _TempoNumericButton('3', numericButtonCallback),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_tempoUnderEdit.isNotEmpty) {
                        setState(() {
                          _tempoUnderEdit.removeLast();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('Del'),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _TempoNumericButton('0', numericButtonCallback),
                ),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  void numericButtonCallback(String digit) {
    if (_tempoUnderEdit.length < 4) {
      setState(() {
        _dirty = true;
        _tempoUnderEdit.add(digit);
      });
    }
  }
}

class _TempoNumericButton extends StatelessWidget {
  const _TempoNumericButton(this.number, this.callback);

  final String number;
  final Function callback;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        callback(number);
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(number),
          ),
        ),
      ),
    );
  }
}
