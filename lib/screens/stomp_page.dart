import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'prorgam_scaffold.dart';
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

class StompButton extends StatelessWidget {
  const StompButton(this.effectCategoryId, {super.key});

  final String effectCategoryId;

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceModel>(
      builder: (context, device, child) {
        EffectBlock? effectBlock = device.getEffectBlock(effectCategoryId);
        if (effectBlock == null) {
          return const Text('');
        }
        Color blockColor = effectBlock.definition.category.color;

        Color backgroundColor = device.isEffectOn(effectBlock)
            ? blockColor
            : Theme.of(context).colorScheme.background;
        Color textColor = device.isEffectOn(effectBlock)
            ? Theme.of(context).colorScheme.background
            : blockColor;

        return GestureDetector(
            onTap: () => {device.toggleEffectBlock(effectCategoryId)},
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
                    child: Text(
                      effectBlock.definition.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: textColor,
                            decoration: effectBlock.isParallel
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            decorationStyle: TextDecorationStyle.double,
                            decorationThickness: 2,
                            decorationColor: textColor,
                          ),
                    ),
                  )),
            ));
      },
    );
  }
}
