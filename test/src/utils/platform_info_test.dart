import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/utils.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  void expectPlatform(
    TargetPlatform platform, {
    bool desktop = false,
    bool mobile = false,
  }) {
    debugDefaultTargetPlatformOverride = platform;
    expect(JPlatformInfo.isDesktop, desktop);
    expect(JPlatformInfo.isDesktopOrWeb, desktop);
    expect(JPlatformInfo.isMobile, mobile);
    expect(JPlatformInfo.isWindows, platform == TargetPlatform.windows);
    expect(JPlatformInfo.isLinux, platform == TargetPlatform.linux);
    expect(JPlatformInfo.isMacOS, platform == TargetPlatform.macOS);
    expect(JPlatformInfo.isAndroid, platform == TargetPlatform.android);
    expect(JPlatformInfo.isIOS, platform == TargetPlatform.iOS);
  }

  test('classifies desktop platforms', () {
    expectPlatform(TargetPlatform.macOS, desktop: true);
    expectPlatform(TargetPlatform.windows, desktop: true);
    expectPlatform(TargetPlatform.linux, desktop: true);
  });

  test('classifies mobile platforms', () {
    expectPlatform(TargetPlatform.android, mobile: true);
    expectPlatform(TargetPlatform.iOS, mobile: true);
  });

  test('other platforms are neither desktop nor mobile', () {
    expectPlatform(TargetPlatform.fuchsia);
  });

  testWidgets('pixelRatio reflects the first view', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    expect(JPlatformInfo.pixelRatio, 3.0);
  });
}
