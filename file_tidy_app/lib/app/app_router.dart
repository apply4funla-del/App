import 'package:file_tidy_app/features/auth/presentation/sign_in_screen.dart';
import 'package:file_tidy_app/features/connectors/presentation/connector_picker_screen.dart';
import 'package:file_tidy_app/features/file_browser/presentation/file_explorer_screen.dart';
import 'package:file_tidy_app/features/history_undo/presentation/history_screen.dart';
import 'package:file_tidy_app/features/onboarding/presentation/welcome_screen.dart';
import 'package:file_tidy_app/features/permissions/presentation/folder_permission_screen.dart';
import 'package:file_tidy_app/features/privacy_center/presentation/privacy_center_screen.dart';
import 'package:file_tidy_app/features/settings/presentation/settings_screen.dart';
import 'package:file_tidy_app/features/splash/presentation/splash_screen.dart';
import 'package:file_tidy_app/features/subscription/presentation/subscription_screen.dart';
import 'package:file_tidy_app/features/tidyup_non_ai/presentation/tidy_up_setup_screen.dart';
import 'package:file_tidy_app/features/tidyup_non_ai/presentation/tidy_up_review_screen.dart';
import 'package:file_tidy_app/features/usb_archive/presentation/usb_archive_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String connectorPicker = '/connectors';
  static const String folderPermission = '/folder-permission';
  static const String explorer = '/explorer';
  static const String tidyUpSetup = '/tidy-up-setup';
  static const String tidyUpReview = '/tidy-up-review';
  static const String history = '/history';
  static const String privacy = '/privacy';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String usbArchive = '/usb-archive';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _material(const SplashScreen());
      case AppRoutes.welcome:
        return _material(const WelcomeScreen());
      case AppRoutes.signIn:
        return _material(const SignInScreen());
      case AppRoutes.connectorPicker:
        return _material(const ConnectorPickerScreen());
      case AppRoutes.folderPermission:
        return _material(const FolderPermissionScreen());
      case AppRoutes.explorer:
        return _material(const FileExplorerScreen());
      case AppRoutes.tidyUpSetup:
        return _material(const TidyUpSetupScreen());
      case AppRoutes.tidyUpReview:
        return _material(const TidyUpReviewScreen());
      case AppRoutes.history:
        return _material(const HistoryScreen());
      case AppRoutes.privacy:
        return _material(const PrivacyCenterScreen());
      case AppRoutes.settings:
        return _material(const SettingsScreen());
      case AppRoutes.subscription:
        return _material(const SubscriptionScreen());
      case AppRoutes.usbArchive:
        return _material(const UsbArchiveScreen());
      default:
        return _material(
          Scaffold(
            body: Center(
              child: Text('Unknown route: ${settings.name}'),
            ),
          ),
        );
    }
  }

  static MaterialPageRoute<dynamic> _material(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
