import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            device.toggleTempoDisplayMode();
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
                        flex: 2,
                        child: Container(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              device.showTempoInMillisec
                                  ? ((60 / device.tempo) * 1000)
                                      .floor()
                                      .toString()
                                  : device.tempo.toString(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    color: blockColor,
                                  ),
                            ))),
                    Expanded(
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
