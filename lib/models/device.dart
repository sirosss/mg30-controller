import 'dart:async';
import 'dart:developer';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

class DeviceModel extends ChangeNotifier {
  bool isInitialized = false;

  MG30VerificationState mg30verificationState = MG30VerificationState.init;
  bool loadPresetDone = false;

  MidiDevice? _midiDevice;
  StreamSubscription<MidiPacket>? _onMidiDataReceivedStreamSubscription;

  final Map<String, EffectCategory> _effectCategories = {};

  final List<EffectBlock> _effectChain = [];
  final Map<String, EffectBlock> _effectMap = {};

  int _programNo = 0;
  final List<String> _programNames = [];
  int _scene = 0;

  // Range: 40-480
  int _tempo = 40;
  DateTime _lastTapTempo = DateTime.now();
  bool _showTempoInMillisec = false;

  MidiDevice get midiDevice {
    return _midiDevice!;
  }

  int get programNo {
    return _programNo;
  }

  String get programName {
    return getProgramName(_programNo);
  }

  String getProgramName(int programNo) {
    return programNo < _programNames.length ? _programNames[programNo] : '-';
  }

  int get scene {
    return _scene;
  }

  int get tempo {
    return _tempo;
  }

  bool get showTempoInMillisec {
    return _showTempoInMillisec;
  }

  List<EffectBlock> get effectChain {
    return _effectChain;
  }

  Future<void> connectToMG30(MidiDevice mg30) async {
    var midi = MidiCommand();

    if (_onMidiDataReceivedStreamSubscription != null) {
      _onMidiDataReceivedStreamSubscription!.cancel();
      _onMidiDataReceivedStreamSubscription = null;
    }

    if (_midiDevice != null) {
      midi.disconnectDevice(_midiDevice!);
      _midiDevice = null;
    }

    await midi.connectToDevice(mg30);
    _midiDevice = mg30;

    // Check if device is MG-30
    final checkMIDIDeviceSubscription =
        midi.onMidiDataReceived!.listen(_checkMIDIDevice);

    try {
      mg30verificationState = MG30VerificationState.init;
      midi.sendData(Uint8List.fromList([0xF0, 0x43, 0x58, 0x00, 0xF7]),
          deviceId: _midiDevice?.id, timestamp: 0);

      int counter = 0;
      while (counter < 50) {
        if (mg30verificationState != MG30VerificationState.init) {
          break;
        }

        await Future.delayed(const Duration(milliseconds: 100));
        counter += 1;
      }

      if (mg30verificationState != MG30VerificationState.verified) {
        throw Exception(
            'The selected MIDI device is not an MG-30 version 4.0.3');
      }

      log('MG-30 detected');
    } finally {
      checkMIDIDeviceSubscription.cancel();
    }

    // Load device data
    final loadAllDeviceDataSubscription =
        midi.onMidiDataReceived!.listen(_loadAllDeviceData);

    try {
      loadPresetDone = false;
      _programNo = 0;
      _programNames.clear();
      _scene = 0;
      _sendGetCurrentProgramNoCommand(midi);

      int counter = 0;
      while (!loadPresetDone && (counter < 100)) {
        await Future.delayed(const Duration(milliseconds: 100));
        counter += 1;
      }

      if (!loadPresetDone) {
        throw Exception('Error during loading presets');
      }

      log('MG-30 presets loaded');
    } finally {
      loadAllDeviceDataSubscription.cancel();
    }

    // Listen to live MIDI messages
    _onMidiDataReceivedStreamSubscription ??=
        midi.onMidiDataReceived!.listen(_onMidiDataReceived);
  }

  void _checkMIDIDevice(MidiPacket packet) {
    if (_isMidiMessageToBeProcessed(packet)) {
      final data = packet.data;
      if (data[0] == 0xF0) {
        if ((data.length == 45) && (_toHex(data.sublist(1, 4)) == '43 58 10')) {
          if (_toHex(data.sublist(4, 10)) == '76 34 2E 30 2E 33') {
            mg30verificationState = MG30VerificationState.verified;
          } else {
            mg30verificationState = MG30VerificationState.unknown;
          }
        }
      }
    }
  }

  void _loadAllDeviceData(MidiPacket packet) {
    try {
      final midi = MidiCommand();
      if (_isMidiMessageToBeProcessed(packet)) {
        final data = packet.data;
        if (data[0] == 0xF0) {
          if ((data.length == 218) &&
              (_toHex(data.sublist(1, 6)) == '43 58 70 0B 02')) {
            // Response from get preset data
            int loadedProgramNo = data[6];
            _programNames.add(_convertProgramName(data.sublist(165, 189)));

            if (loadedProgramNo == 127) {
              loadPresetDone = true;
            } else {
              _sendLoadPresetCommand(midi, loadedProgramNo + 1);
            }
          } else if ((data.length == 218) &&
              (_toHex(data.sublist(1, 6)) == '43 58 70 0C 02')) {
            // Response from get current effect state
            _populateEffectChain(data);
            _sendLoadPresetCommand(midi, 0);
          } else if ((data.length == 15) &&
              (_toHex(data.sublist(1, 6)) == '43 58 70 15 02')) {
            // Response from get current program no
            _programNo = data[6];
            _scene = data[9];
            _sendGetCurrentEffectStateCommand(midi);
          }
        }
      }
    } catch (error, stackTrace) {
      log('Error during processing MIDI message',
          error: error, stackTrace: stackTrace);
    }
  }

  void _onMidiDataReceived(MidiPacket packet) {
    try {
      final midi = MidiCommand();
      if (_isMidiMessageToBeProcessed(packet)) {
        final data = packet.data;
        if (data[0] == 0xC0) {
          // Incoming program change
          _programNo = data[1];
          _scene = 0;
          _sendGetCurrentEffectStateCommand(midi);
          notifyListeners();
        } else if (data[0] == 0xB0) {
          // Incoming CC
          if (data[1] == 0x4F) {
            _scene = data[2];
            notifyListeners();
          } else {
            for (int i = 0; i < _effectChain.length; i++) {
              final block = _effectChain[i];
              if (data[1] == block.definition.category.ccNo) {
                if (data[2] == block.definition.codeCcOn) {
                  block.isOn[_scene] = true;
                } else if (data[2] == block.definition.codeCcOff) {
                  block.isOn[_scene] = false;
                } else {
                  // Unknown value => effect type changed
                  _sendGetCurrentEffectStateCommand(midi);
                }

                notifyListeners();
              }
            }
          }
        } else if ((data.length == 15) &&
            (_toHex(data) == 'F0 43 58 70 7E 02 0D 00 00 00 00 00 00 00 F7')) {
          // Effect order changed
          _sendGetCurrentEffectStateCommand(midi);
        } else if ((data.length == 15) &&
            (_toHex(data) == 'F0 43 58 70 7E 02 03 00 00 00 00 00 00 00 F7')) {
          // Tempo changed
          _sendGetCurrentEffectStateCommand(midi);
        } else if ((data.length == 15) &&
            (_toHex(data) == 'F0 43 58 70 7E 02 13 00 00 00 00 00 00 00 F7')) {
          // Control assignment changed
          _sendGetCurrentEffectStateCommand(midi);
        } else if ((data.length == 15) &&
            (_toHex(data.sublist(0, 7)) == 'F0 43 58 70 7E 02 0B')) {
          // Preset saved
          _programNo = data[8];
          _scene = 0;
          _sendGetCurrentEffectStateCommand(midi);
        } else if ((data.length == 218) &&
            (_toHex(data.sublist(0, 6)) == 'F0 43 58 70 0C 02')) {
          // Response from get current effect state
          _populateEffectChain(data);
          notifyListeners();
        }
      }
    } catch (error, stackTrace) {
      log('Error during processing MIDI message',
          error: error, stackTrace: stackTrace);
    }
  }

  String _convertProgramName(Uint8List data) {
    List<String> result = [];
    int counter = 0;
    while (counter < data.length) {
      if (data[counter] != 0) {
        result.add(String.fromCharCode(data[counter]));
      } else {
        break;
      }

      int secondChar = data[counter + 2] ~/ 2;
      if (data[counter + 1] == 1) {
        secondChar += 0x40;
      }

      if (secondChar != 0) {
        result.add(String.fromCharCode(secondChar));
      } else {
        break;
      }

      counter += 3;
    }
    return result.join();
  }

  void _populateEffectChain(Uint8List data) {
    _effectChain.clear();
    _effectMap.clear();

    if (_programNo < _programNames.length) {
      _programNames[_programNo] = _convertProgramName(data.sublist(165, 189));
    }

    _tempo = (data[143] * 64) + data[144];

    final effectTypeChain = _getEffectTypeChain(data);

    for (int i = 0; i < effectTypeChain.length; i++) {
      switch (effectTypeChain[i]) {
        case 0:
          EffectBlock effectBlock =
              _getSingleCodeTypeBlock(data, 'WAH', 8, 2, 1);
          if (data[194] != 2) {
            effectBlock.isEnabled = false;
          }
          _addEffectBlock(effectBlock);
          break;
        case 1:
          _addEffectBlock(_getDualCodeTypeBlock(data, 'CMP', 9, 4, 1));
          break;
        case 2:
          _addEffectBlock(_getSingleCodeTypeBlock(data, 'EFX', 11, 8, 1));
          break;
        case 3:
          _addEffectBlock(_getDualCodeTypeBlock(data, 'AMP', 12, 16, 1));
          break;
        case 4:
          _addEffectBlock(_getSingleCodeTypeBlock(data, 'EQ', 14, 32, 1));
          break;
        case 5:
          _addEffectBlock(_getDualCodeTypeBlock(data, 'GATE', 15, 64, 1));
          break;
        case 6:
          _addEffectBlock(_getSingleCodeTypeBlock(data, 'MOD', 17, 1, 0));
          break;
        case 7:
          _addEffectBlock(_getDualCodeTypeBlock(data, 'DLY', 18, 2, 0));
          break;
        case 8:
          _addEffectBlock(_getSingleCodeTypeBlock(data, 'RVB', 20, 1, 2));
          break;
        case 9:
          _addEffectBlock(_getDualCodeTypeBlock(data, 'IR', 21, 2, 2));
          break;
        case 10:
          _addEffectBlock(_getDualCodeTypeBlock(data, 'S/R', 22, 4, 2));
          break;
        case 11:
          _addEffectBlock(_getDualCodeTypeBlock(data, 'VOL', 24, 8, 2));
          break;
        default:
          throw Exception('Unknown effect type code: $effectTypeChain[i]');
      }
    }

    List<EffectBlock> modDlyRvb = _effectChain
        .where((effectBlock) =>
            ['MOD', 'DLY', 'RVB'].contains(effectBlock.definition.category.id))
        .toList();

    if (modDlyRvb.length == 3) {
      if (data[146] & 2 == 2) {
        modDlyRvb[0].isParallel = true;
        modDlyRvb[1].isParallel = true;
      }
      if (data[146] & 4 == 4) {
        modDlyRvb[1].isParallel = true;
        modDlyRvb[2].isParallel = true;
      }
    }
  }

  void _addEffectBlock(EffectBlock effectBlock) {
    _effectChain.add(effectBlock);
    _effectMap[effectBlock.definition.category.id] = effectBlock;
  }

  List<int> _getEffectTypeChain(Uint8List data) {
    List<int> effectTypeChain = [];
    effectTypeChain.add(data[147]);
    effectTypeChain.add(data[149] ~/ 2);
    effectTypeChain.add(data[150]);
    effectTypeChain.add(data[152] ~/ 2);
    effectTypeChain.add(data[153]);
    effectTypeChain.add(data[155] ~/ 2);
    effectTypeChain.add(data[156]);
    effectTypeChain.add(data[158] ~/ 2);
    effectTypeChain.add(data[159]);
    effectTypeChain.add(data[161] ~/ 2);
    effectTypeChain.add(data[162]);
    effectTypeChain.add(data[164] ~/ 2);
    return effectTypeChain;
  }

  EffectBlock _getSingleCodeTypeBlock(Uint8List data, String blockType,
      int dataByteLocation, int mask, int sceneByteOffset) {
    final category = _effectCategories[blockType];
    if (category != null) {
      final definition = category.saveOnEffects[data[dataByteLocation]];
      if (definition != null) {
        final bool s1Status = data[208 + sceneByteOffset] & mask == mask;
        final bool s2Status = data[211 + sceneByteOffset] & mask == mask;
        final bool s3Status = data[214 + sceneByteOffset] & mask == mask;
        return EffectBlock(definition, [s1Status, s2Status, s3Status]);
      }
    }

    throw Exception('Unrecognized $blockType preset data');
  }

  EffectBlock _getDualCodeTypeBlock(Uint8List data, String blockType,
      int dataByteLocation, int mask, int sceneByteOffset) {
    final category = _effectCategories[blockType];
    if (category != null) {
      var definition = category.saveOnEffects[data[dataByteLocation]];
      definition ??= category.saveOffEffects[data[dataByteLocation]];

      if (definition != null) {
        final bool s1Status = data[208 + sceneByteOffset] & mask == mask;
        final bool s2Status = data[211 + sceneByteOffset] & mask == mask;
        final bool s3Status = data[214 + sceneByteOffset] & mask == mask;
        return EffectBlock(definition, [s1Status, s2Status, s3Status]);
      }
    }

    throw Exception('Unrecognized $blockType preset data');
  }

  bool _isMidiMessageToBeProcessed(MidiPacket packet) {
    if (kDebugMode) {
      final hex = _toHex(packet.data);
      log('Received: $hex');
    }

    if (_midiDevice == null) {
      if (kDebugMode) {
        log('No connected MIDI device');
      }
      return false;
    }

    if (packet.device.id != _midiDevice?.id) {
      if (kDebugMode) {
        log('Data is not from the selected MIDI device');
      }
      return false;
    }

    return true;
  }

  void _sendLoadPresetCommand(MidiCommand midi, int programNo) {
    midi.sendData(
        Uint8List.fromList([
          0xF0,
          0x43,
          0x58,
          0x70,
          0x0B,
          0x00,
          programNo,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0xF7
        ]),
        deviceId: _midiDevice?.id,
        timestamp: 0);
  }

  void _sendGetCurrentProgramNoCommand(MidiCommand midi) {
    midi.sendData(
        Uint8List.fromList([0xF0, 0x43, 0x58, 0x70, 0x15, 0x00, 0xF7]),
        deviceId: _midiDevice?.id,
        timestamp: 0);
  }

  void _sendGetCurrentEffectStateCommand(MidiCommand midi) {
    midi.sendData(
        Uint8List.fromList([0xF0, 0x43, 0x58, 0x70, 0x0C, 0x00, 0xF7]),
        deviceId: _midiDevice?.id,
        timestamp: 0);
  }

  void _sendSetTempoCommand(MidiCommand midi) {
    midi.sendData(
        Uint8List.fromList([
          0xF0,
          0x43,
          0x58,
          0x70,
          0x03,
          0x01,
          _tempo ~/ 128,
          _tempo % 128,
          0x03,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0xF7
        ]),
        deviceId: _midiDevice?.id,
        timestamp: 0);
  }

  void _sendProgramChangeCommand(MidiCommand midi, int programNo) {
    midi.sendData(Uint8List.fromList([0xC0, programNo]),
        deviceId: _midiDevice?.id, timestamp: 0);

    _sendGetCurrentEffectStateCommand(midi);
  }

  void _sendCCCommand(MidiCommand midi, int cc, int value) {
    midi.sendData(Uint8List.fromList([0xB0, cc, value]),
        deviceId: _midiDevice?.id, timestamp: 0);
  }

  EffectBlock? getEffectBlock(String categoryId) {
    return _effectMap[categoryId];
  }

  bool isEffectOn(EffectBlock block) {
    return block.isOn[_scene];
  }

  void changeProgram(programNo) {
    final midi = MidiCommand();
    _programNo = programNo;
    _scene = 0;
    _sendProgramChangeCommand(midi, programNo);
    _sendLoadPresetCommand(midi, programNo);
    notifyListeners();
  }

  void toggleEffectBlock(String categoryId) {
    final EffectBlock? effectBlock = _effectMap[categoryId];
    if (effectBlock != null) {
      final definition = effectBlock.definition;
      final ccValue =
          effectBlock.isOn[_scene] ? definition.codeCcOff : definition.codeCcOn;

      log('Send CC#${definition.category.ccNo}: $ccValue');
      _sendCCCommand(MidiCommand(), definition.category.ccNo, ccValue);

      effectBlock.isOn[_scene] = !effectBlock.isOn[_scene];
      notifyListeners();
    }
  }

  void tapTempo() {
    final DateTime now = DateTime.now();
    final duration = now.difference(_lastTapTempo);
    final int newTempo = (60 / (duration.inMilliseconds / 1000)).round();
    if ((newTempo >= 40) && (newTempo <= 480)) {
      _tempo = newTempo;
      log('New Tempo: $_tempo');
      _sendSetTempoCommand(MidiCommand());
      notifyListeners();
    }
    _lastTapTempo = now;
  }

  void toggleTempoDisplayMode() {
    _showTempoInMillisec = !_showTempoInMillisec;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_onMidiDataReceivedStreamSubscription != null) {
      _onMidiDataReceivedStreamSubscription!.cancel();
      _onMidiDataReceivedStreamSubscription = null;
    }

    if (_midiDevice != null) {
      MidiCommand().disconnectDevice(_midiDevice!);
      _midiDevice = null;
    }

    super.dispose();
  }

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    isInitialized = true;
    log('Initializing DeviceModel ...');
    await _loadCategoryDefinition();
    await _loadEffectDefinition();

    if (kDebugMode) {
      _loadDummyEffectChain();
    }
    log('DeviceModel initialized');
  }

  Future<void> _loadCategoryDefinition() async {
    _effectCategories.clear();

    final effectCategoryCsv = await rootBundle
        .loadString("assets/effect_category.csv", cache: !kDebugMode);
    List<List<dynamic>> effectCategoryList =
        const CsvToListConverter().convert(effectCategoryCsv);

    if (effectCategoryList.length > 1) {
      for (int i = 1; i < effectCategoryList.length; i++) {
        final line = effectCategoryList[i];

        final color = Color.fromARGB(255, line[3], line[4], line[5]);
        final category = EffectCategory(line[0], line[1], line[2], color);

        _effectCategories[category.id] = category;
      }
    }
  }

  Future<void> _loadEffectDefinition() async {
    final effectCsv =
        await rootBundle.loadString("assets/effect.csv", cache: !kDebugMode);
    List<List<dynamic>> effectList =
        const CsvToListConverter().convert(effectCsv);

    if (effectList.length > 1) {
      for (int i = 1; i < effectList.length; i++) {
        final line = effectList[i];

        var category = _effectCategories[line[0]];
        if (category != null) {
          var effect =
              EffectDefinition(category, line[2].toString(), line[5], line[6]);

          category.saveOnEffects[line[3]] = effect;
          if (line[4] != null && line[4] is int) {
            category.saveOffEffects[line[4]] = effect;
          }
        }
      }
    }
  }

  void _loadDummyEffectChain() {
    _effectChain.clear();
    _effectChain.add(EffectBlock(_effectCategories['WAH']!.saveOnEffects[8]!,
        [true, true, true], true, false));
    _effectChain.add(EffectBlock(_effectCategories['CMP']!.saveOnEffects[6]!,
        [false, false, false], true, false));
    _effectChain.add(EffectBlock(_effectCategories['EFX']!.saveOnEffects[16]!,
        [true, true, true], true, false));
    _effectChain.add(EffectBlock(_effectCategories['AMP']!.saveOnEffects[13]!,
        [true, true, true], true, false));
    _effectChain.add(EffectBlock(_effectCategories['EQ']!.saveOnEffects[6]!,
        [false, false, false], true, false));
    _effectChain.add(EffectBlock(_effectCategories['GATE']!.saveOnEffects[1]!,
        [true, true, true], true, false));
    _effectChain.add(EffectBlock(_effectCategories['MOD']!.saveOnEffects[26]!,
        [false, false, false], true, false));
    _effectChain.add(EffectBlock(_effectCategories['DLY']!.saveOnEffects[4]!,
        [false, false, false], true, false));
    _effectChain.add(EffectBlock(_effectCategories['RVB']!.saveOnEffects[8]!,
        [false, false, false], true, false));
    _effectChain.add(EffectBlock(
        _effectCategories['IR']!.saveOnEffects[7]!, [true, true, true], false));
    _effectChain.add(EffectBlock(_effectCategories['S/R']!.saveOffEffects[1]!,
        [false, false, false], true, false));
    _effectChain.add(EffectBlock(_effectCategories['VOL']!.saveOnEffects[1]!,
        [true, true, true], true, false));
  }

  String _toHex(Uint8List data, {String separator = ' '}) {
    return data.map((value) {
      final str = value.toRadixString(16).toUpperCase();
      return str.length == 1 ? '0$str' : str;
    }).join(separator);
  }
}

class EffectCategory {
  final String id;
  final int saveCode;
  final int ccNo;
  final Color color;
  final Map<int, EffectDefinition> saveOnEffects = {};
  final Map<int, EffectDefinition> saveOffEffects = {};

  EffectCategory(this.id, this.saveCode, this.ccNo, this.color);
}

class EffectDefinition {
  final EffectCategory category;
  final String name;
  final int codeCcOn;
  final int codeCcOff;

  EffectDefinition(this.category, this.name, this.codeCcOn, this.codeCcOff);
}

class EffectBlock {
  final EffectDefinition definition;
  List<bool> isOn;
  bool isEnabled;
  bool isParallel;

  EffectBlock(this.definition, this.isOn,
      [this.isEnabled = true, this.isParallel = false]);
}

enum MG30VerificationState { init, verified, unknown }
