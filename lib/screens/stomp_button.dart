import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/models/device.dart';

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

        Color blockColor = effectBlock.isEnabled
            ? effectBlock.definition.category.color
            : const Color.fromARGB(255, 64, 64, 64);

        Color backgroundColor = device.isEffectOn(effectBlock)
            ? blockColor
            : Theme.of(context).colorScheme.background;
        Color textColor = device.isEffectOn(effectBlock)
            ? Theme.of(context).colorScheme.background
            : blockColor;

        return GestureDetector(
            onTap: () {
              if (effectBlock.isEnabled) {
                device.toggleEffectBlock(effectCategoryId);
              }
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
                    child: Text(
                      effectBlock.isEnabled
                          ? effectBlock.definition.name
                          : effectBlock.definition.category.id,
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
