import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:mg30controller/app_constants.dart';
import 'package:provider/provider.dart';

import '/models/device.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        centerTitle: true,
      ),
      body: const DeviceSelection(),
    );
  }
}

class DeviceSelection extends StatefulWidget {
  const DeviceSelection({super.key});

  @override
  State<DeviceSelection> createState() => DeviceSelectionState();
}

class DeviceSelectionState extends State<DeviceSelection> {
  bool inProgress = false;

  MidiDevice? _selectedDevice;
  final List<MidiDevice> _allDevices = [];

  DeviceSelectionState() {
    _refreshMidiDevices();
  }

  Future<void> _refreshMidiDevices() async {
    var midiDevices = await MidiCommand().devices;
    setState(() {
      _allDevices.clear();
      _allDevices.addAll(midiDevices!.toList());
      for (int i = 0; i < _allDevices.length; i++) {
        final device = _allDevices[i];
        if (device.name.contains('NUX') && device.name.contains('MG-30')) {
          _selectedDevice = device;
        }
      }
      log('Fount ${_allDevices.length} MIDI device(s)');
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuEntry<MidiDevice>> dropdownMenuEntries = [];
    for (var device in _allDevices) {
      dropdownMenuEntries
          .add(DropdownMenuEntry(value: device, label: device.name));
    }

    double dropdownWidth = MediaQuery.of(context).size.width / 3;
    if (dropdownWidth < 300) {
      dropdownWidth = 300;
    }

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(5),
          child: Text('Select MG-30 MIDI Device',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        Text('For MG-30 V4.0.3',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.orange)),
        Container(
          padding: const EdgeInsets.all(5),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            DropdownMenu<MidiDevice>(
              initialSelection: _selectedDevice,
              dropdownMenuEntries: dropdownMenuEntries,
              width: dropdownWidth,
            ),
            IconButton(
                onPressed: () {
                  _refreshMidiDevices();
                },
                icon: const Icon(Icons.replay)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: Consumer<DeviceModel>(builder: (context, device, child) {
            device.initialize();
            return ElevatedButton(
              onPressed: () {
                if (_selectedDevice != null) {
                  context.loaderOverlay.show();
                  device.connectToMG30(_selectedDevice!).then((value) {
                    context.loaderOverlay.hide();
                    context.go('/stomp');
                  }).catchError((e) {
                    context.loaderOverlay.hide();
                    log(e.toString());
                    var snackBar = SnackBar(
                      content: Text(e.toString()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  });
                } else {
                  const snackBar = SnackBar(
                    content: Text('Please select an MG-30 MIDI device.'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: const Text("Connect"),
            );
          }),
        ),
      ]),
    );
  }
}
