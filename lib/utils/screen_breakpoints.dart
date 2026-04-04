import 'package:flutter/material.dart';

class ScreenBreakpoints {
  static const double largeDeviceShortestSide = 600;

  static bool isLargeDevice(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= largeDeviceShortestSide;
  }
}
