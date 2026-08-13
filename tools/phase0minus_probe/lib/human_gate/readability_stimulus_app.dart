import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final class ReadabilityStimulus {
  const ReadabilityStimulus({
    required this.id,
    required this.asset,
    required this.sha256,
  });

  final String id;
  final String asset;
  final String sha256;
}

Future<List<ReadabilityStimulus>> loadReadabilityStimuli() async {
  final raw = await rootBundle.loadString('assets/readability/manifest.json');
  final decoded = jsonDecode(raw) as Map<String, Object?>;
  final entries = decoded['stimuli']! as List<Object?>;
  final stimuli = [
    for (final entry in entries.cast<Map<String, Object?>>())
      ReadabilityStimulus(
        id: entry['id']! as String,
        asset: entry['asset']! as String,
        sha256: entry['sha256']! as String,
      ),
  ];
  for (final stimulus in stimuli) {
    final bytes = await rootBundle.load(stimulus.asset);
    final actual = sha256.convert(bytes.buffer.asUint8List()).toString();
    if (actual != stimulus.sha256) {
      throw StateError('STIMULUS_HASH_MISMATCH ${stimulus.id}');
    }
  }
  return stimuli;
}

final class ReadabilityStimulusApp extends StatelessWidget {
  const ReadabilityStimulusApp({
    super.key,
    this.exposure = const Duration(seconds: 1),
  });

  final Duration exposure;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: FutureBuilder<List<ReadabilityStimulus>>(
      future: loadReadabilityStimuli(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('STIMULUS_ERROR ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ReadabilityStimulusSession(
          stimuli: snapshot.data!,
          exposure: exposure,
        );
      },
    ),
  );
}

enum ReadabilityStage { ready, visible, masked, complete }

final class ReadabilityStimulusSession extends StatefulWidget {
  const ReadabilityStimulusSession({
    required this.stimuli,
    required this.exposure,
    this.prepareStimulus,
    super.key,
  });

  final List<ReadabilityStimulus> stimuli;
  final Duration exposure;
  final Future<void> Function(BuildContext, ReadabilityStimulus)?
  prepareStimulus;

  @override
  State<ReadabilityStimulusSession> createState() =>
      _ReadabilityStimulusSessionState();
}

final class _ReadabilityStimulusSessionState
    extends State<ReadabilityStimulusSession> {
  int index = 0;
  ReadabilityStage stage = ReadabilityStage.ready;
  Timer? timer;

  ReadabilityStimulus get stimulus => widget.stimuli[index];

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> showCurrent() async {
    if (stage != ReadabilityStage.ready) return;
    final prepare = widget.prepareStimulus;
    if (prepare == null) {
      await precacheImage(AssetImage(stimulus.asset), context);
    } else {
      await prepare(context, stimulus);
    }
    if (!mounted || stage != ReadabilityStage.ready) return;
    setState(() => stage = ReadabilityStage.visible);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || stage != ReadabilityStage.visible) return;
      debugPrint('READABILITY_STIMULUS_VISIBLE ${stimulus.id}');
      timer = Timer(widget.exposure, () {
        if (!mounted) return;
        setState(() => stage = ReadabilityStage.masked);
        debugPrint('READABILITY_STIMULUS_MASKED ${stimulus.id}');
      });
    });
  }

  void next() {
    if (stage != ReadabilityStage.masked) return;
    if (index + 1 >= widget.stimuli.length) {
      setState(() => stage = ReadabilityStage.complete);
      debugPrint('READABILITY_STIMULUS_COMPLETE');
      return;
    }
    setState(() {
      index++;
      stage = ReadabilityStage.ready;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff17191c),
    body: switch (stage) {
      ReadabilityStage.visible => SizedBox.expand(
        key: const ValueKey('stimulus-visible'),
        child: Image.asset(stimulus.asset, fit: BoxFit.contain),
      ),
      ReadabilityStage.masked => _Prompt(
        key: const ValueKey('stimulus-masked'),
        title: '请回答',
        body: '主角在哪里？危险来自哪里？',
        button: '下一帧',
        onPressed: next,
        progress: '${index + 1}/${widget.stimuli.length}',
      ),
      ReadabilityStage.complete => const Center(
        key: ValueKey('stimulus-complete'),
        child: Text('五帧已完成，请保存观察记录。'),
      ),
      ReadabilityStage.ready => _Prompt(
        key: const ValueKey('stimulus-ready'),
        title: '可读性快照',
        body: '点击后画面只显示 1 秒。测试者不得提前看到答案。',
        button: '显示第 ${index + 1} 帧',
        onPressed: () => unawaited(showCurrent()),
        progress: '${index + 1}/${widget.stimuli.length}',
      ),
    },
  );
}

final class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
    required this.progress,
    super.key,
  });

  final String title;
  final String body;
  final String button;
  final VoidCallback onPressed;
  final String progress;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(progress, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(body),
        const SizedBox(height: 28),
        FilledButton(onPressed: onPressed, child: Text(button)),
      ],
    ),
  );
}
