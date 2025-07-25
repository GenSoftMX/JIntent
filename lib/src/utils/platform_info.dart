import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A utility class for identifying the current platform and its capabilities.
///
/// The `PlatformInfo` class provides static properties and methods to determine
/// the type of platform the app is running on, such as mobile, desktop, or web.
/// It also includes functionality to check the device's internet connectivity.
class JPlatformInfo {
  /// A list of desktop platforms supported by this utility.
  static const _desktopPlatforms = [
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ];

  /// A list of mobile platforms supported by this utility.
  static const _mobilePlatforms = [TargetPlatform.android, TargetPlatform.iOS];

  /// Indicates if the app is running on a desktop platform (not web).
  ///
  /// Returns `true` if the current platform is macOS, Windows, or Linux,
  /// and the app is not running on the web. Otherwise, it returns `false`.
  static bool get isDesktop =>
      _desktopPlatforms.contains(defaultTargetPlatform) && !kIsWeb;

  /// Indicates if the app is running on a desktop platform or the web.
  ///
  /// Returns `true` if the current platform is macOS, Windows, Linux, or the web.
  static bool get isDesktopOrWeb => isDesktop || kIsWeb;

  /// Indicates if the app is running on a mobile platform (not web).
  ///
  /// Returns `true` if the current platform is Android or iOS, and the app is
  /// not running on the web. Otherwise, it returns `false`.
  static bool get isMobile =>
      _mobilePlatforms.contains(defaultTargetPlatform) && !kIsWeb;

  /// The pixel density of the device's display.
  ///
  /// Returns the pixel ratio of the first view managed by the platform dispatcher.
  static double get pixelRatio =>
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  /// Indicates if the app is running on a Windows platform.
  static bool get isWindows => defaultTargetPlatform == TargetPlatform.windows;

  /// Indicates if the app is running on a Linux platform.
  static bool get isLinux => defaultTargetPlatform == TargetPlatform.linux;

  /// Indicates if the app is running on a macOS platform.
  static bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  /// Indicates if the app is running on an Android platform.
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Indicates if the app is running on an iOS platform.
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
}
