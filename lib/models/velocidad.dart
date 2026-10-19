enum Velocidad {
  lenta('Lenta', 2.0),
  normal('Normal', 1.0),
  rapida('Rápida', 0.5),
  muyRapida('Muy rápida', 0.2);

  final String etiqueta;
  final double factor; // multiplica las pausas: menor = más rápido

  const Velocidad(this.etiqueta, this.factor);
}