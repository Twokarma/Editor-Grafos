import 'dart:math';
import 'dart:ui';

class AppViewport {
  Offset offset = Offset.zero;
  double scale = 1.0;
  static const double minScale = 0.25;
  static const double maxScale = 3.0;
  static const double maxFitScale = 1.5;

  Offset toWorld(Offset screenPoint){
    return (screenPoint - offset) / scale;
  }

  Offset toScreen(Offset worldPoint){
    return worldPoint * scale + offset;
  }

  void panBy(Offset screenDelta){
    offset += screenDelta;
  }

  void zoomAt(Offset focalScreen, double newScale){
    newScale = newScale.clamp(minScale, maxScale);
    Offset w = toWorld(focalScreen);
    scale = newScale;
    offset = focalScreen - w * scale;
  }

  void zoomBy(Offset focalScreen, double factor){
    zoomAt(focalScreen, factor * scale);
  }

  void reset(){
    offset = Offset.zero;
    scale = 1.0;
  }

  void fitToRect(Rect worldRect, Size viewSize, double padding){
    scale = min((viewSize.width - 2 * padding)/worldRect.width, (viewSize.height - 2 * padding)/worldRect.height).clamp(minScale, maxFitScale);
    offset = viewSize.center(Offset.zero) - worldRect.center * scale;
  }
}