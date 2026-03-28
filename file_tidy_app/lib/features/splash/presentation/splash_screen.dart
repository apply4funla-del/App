import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/lottie_slot.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LottieSlot(fallbackIcon: Icons.folder_copy_outlined),
            SizedBox(height: AppSpacing.md),
            Text('File Tidy Assistant'),
          ],
        ),
      ),
    );
  }
}
