import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final class Phase0bArtSample {
  const Phase0bArtSample({
    required this.asset,
    required this.title,
    required this.boundary,
  });

  final String asset;
  final String title;
  final String boundary;
}

const phase0bArtSamples = <Phase0bArtSample>[
  Phase0bArtSample(
    asset: 'assets/phase0b/phase0b_gather_keyframe_v1.png',
    title: '01 / Gather gameplay keyframe',
    boundary: 'Spatial-control concept; not damage or runtime evidence.',
  ),
  Phase0bArtSample(
    asset: 'assets/phase0b/phase0b_clear_keyframe_v1.png',
    title: '02 / Clear gameplay keyframe',
    boundary: 'Single-primary-effect concept; not an animated asset.',
  ),
  Phase0bArtSample(
    asset: 'assets/phase0b/phase0b_break_keyframe_v1.png',
    title: '03 / Elite break-window keyframe',
    boundary: 'Readability concept; vermilion is reserved for danger.',
  ),
  Phase0bArtSample(
    asset: 'assets/phase0b/phase0b_founder_action_sheet_v1.png',
    title: '04 / Founder six-pose sheet',
    boundary: 'Animation handoff concept; not layer-separated or rigged.',
  ),
  Phase0bArtSample(
    asset: 'assets/phase0b/phase0b_bandit_action_sheet_v1.png',
    title: '05 / Ordinary bandit six-pose sheet',
    boundary: 'Low-cost shared-rig concept; not a sprite atlas.',
  ),
  Phase0bArtSample(
    asset: 'assets/phase0b/phase0b_elite_action_sheet_v1.png',
    title: '06 / Elite four-pose sheet',
    boundary: 'Medium-complexity rig concept; not production animation.',
  ),
];

final class Phase0bArtGalleryApp extends StatelessWidget {
  const Phase0bArtGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4C6D69),
          brightness: Brightness.dark,
        ),
      ),
      home: const Phase0bArtGalleryScreen(),
    );
  }
}

final class Phase0bArtGalleryScreen extends StatefulWidget {
  const Phase0bArtGalleryScreen({super.key});

  @override
  State<Phase0bArtGalleryScreen> createState() =>
      _Phase0bArtGalleryScreenState();
}

final class _Phase0bArtGalleryScreenState
    extends State<Phase0bArtGalleryScreen> {
  var _index = 0;

  void _move(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, phase0bArtSamples.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sample = phase0bArtSamples[_index];
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _GalleryMoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _GalleryMoveIntent(1),
      },
      child: Actions(
        actions: {
          _GalleryMoveIntent: CallbackAction<_GalleryMoveIntent>(
            onInvoke: (intent) {
              _move(intent.delta);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: const Color(0xFF171815),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sample.title,
                                key: const ValueKey('phase0b-gallery-title'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sample.boundary,
                                key: const ValueKey('phase0b-gallery-boundary'),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFFB9B5A8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('phase0b-gallery-previous'),
                          onPressed: _index == 0 ? null : () => _move(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('${_index + 1} / ${phase0bArtSamples.length}'),
                        IconButton(
                          key: const ValueKey('phase0b-gallery-next'),
                          onPressed: _index == phase0bArtSamples.length - 1
                              ? null
                              : () => _move(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEE4CF),
                          border: Border.all(color: const Color(0xFF716B60)),
                        ),
                        child: Center(
                          child: Image.asset(
                            sample.asset,
                            key: ValueKey(sample.asset),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _GalleryMoveIntent extends Intent {
  const _GalleryMoveIntent(this.delta);

  final int delta;
}
