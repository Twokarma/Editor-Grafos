import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/velocidad.dart';

class VelocidadDropdown extends StatelessWidget {
  final Velocidad valor;
  final ValueChanged<Velocidad> onChanged;

  const VelocidadDropdown({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.speed),
        const SizedBox(width: 8),
        DropdownButton<Velocidad>(
          value: valor,
          underline: const SizedBox.shrink(),
          items: [
            for (final v in Velocidad.values)
              DropdownMenuItem(value: v, child: Text(v.etiqueta)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}