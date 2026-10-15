import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TourStep {
  final GlobalKey key;
  final String title;
  final String text;
  final ContentAlign align;
  final ShapeLightFocus shape; // ★ AYUDA: nuevo parámetro

  const TourStep(
    this.key,
    this.title,
    this.text, {
    this.align = ContentAlign.bottom,
    this.shape = ShapeLightFocus.Circle, // ★ AYUDA: por defecto círculo
  });
}

class GraphTour {
  GraphTour._();

  static void show(BuildContext context, List<TourStep> steps) {
    late TutorialCoachMark tutorial;

    final targets = <TargetFocus>[
      for (var i = 0; i < steps.length; i++)
        TargetFocus(
          identify: steps[i].title,
          keyTarget: steps[i].key,
          shape: steps[i].shape, // ★ AYUDA: usa la forma del paso
          radius: 6,
          contents: [
            TargetContent(
              align: steps[i].align,
              builder: (context, controller) => _Bubble(
                step: steps[i],
                index: i,
                total: steps.length,
                onPrev: i == 0 ? null : controller.previous,
                onNext: i == steps.length - 1
                    ? () => tutorial.finish()
                    : controller.next,
              ),
            ),
          ],
        ),
    ];

    tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 6,
      textSkip: 'Saltar',
    )..show(context: context);
  }
}

class _Bubble extends StatelessWidget {
  final TourStep step;
  final int index, total;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  const _Bubble({
    required this.step,
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF5B3FD0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              step.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('${index + 1}/$total',
                    style: const TextStyle(color: Colors.white70)),
                const Spacer(),
                if (onPrev != null)
                  IconButton.filledTonal(
                    onPressed: onPrev,
                    icon: const Icon(Icons.arrow_back),
                  ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: onNext,
                  icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}