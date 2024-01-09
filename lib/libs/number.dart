/* import 'dart:math';

double findNearestCoordinate(Function func, double targetX, double targetY) {
  double nearestX = targetX;
  double nearestY = double.infinity;

  for (double x = targetX - 1; x <= targetX + 1; x += 0.01) {
    double y = func(x);
    double distance =
        sqrt((x - targetX) * (x - targetX) + (y - targetY) * (y - targetY));

    if (distance < nearestY) {
      nearestX = x;
      nearestY = distance;
    }
  }

  return nearestX;
}
 */