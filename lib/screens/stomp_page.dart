import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'prorgam_scaffold.dart';
import 'stomp_button.dart';
import 'tempo_button.dart';
import '/models/device.dart';

class StompPage extends StatelessWidget {
  const StompPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceModel>(builder: (context, device, child) {
      var count = 0;
      final buttonCol = <Widget>[];

      List<EffectBlock> effectChain = device.effectChain
          .where((effectBlock) => effectBlock.definition.category.id != 'VOL')
          .toList();

      for (var row = 0; row < 3; row++) {
        final buttonRow = <Widget>[];
        for (var col = 0; col < 4; col++) {
          if ((row == 2) && (col == 3)) {
            buttonRow.add(const Expanded(child: TempoButton()));
          } else {
            buttonRow.add(Expanded(
                child: StompButton(effectChain[count].definition.category.id)));
          }
          count++;
        }

        buttonCol.add(Expanded(
            child: Row(
          children: buttonRow,
        )));
      }
      return ProgramScaffold(
        body: Column(
          children: buttonCol,
        ),
      );
    });
  }
}
