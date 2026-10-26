import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/widgets/ui/pressable.dart';

void main() => runApp(const MaterialApp(home: PressableDemo()));

class PressableDemo extends StatefulWidget {
  const PressableDemo({super.key});
  @override
  State<PressableDemo> createState() => _PressableDemoState();
}

class _PressableDemoState extends State<PressableDemo> {
  int taps = 0;
  bool reduceMotion = false;

  Widget box(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
    child: Text(text, style: const TextStyle(color: Colors.white)),
  );

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, spacing: 24, children: [
            Text('Taps: $taps'),
            Pressable(onTap: () => setState(() => taps++), child: box('Enabled', Colors.indigo)),
            Pressable(onTap: null, child: box('Disabled', Colors.grey)),
            Pressable(
              hoverLift: 10,
              onTap: () => setState(() => taps++),
              builder: (context, hovered) => box(hovered ? 'Hovered!' : 'Card (builder)', Colors.teal),
            ),
            SwitchListTile(
              title: const Text('Reduce motion'),
              value: reduceMotion,
              onChanged: (v) => setState(() => reduceMotion = v),
            ),
          ]),
        ),
      ),
    );
  }
}