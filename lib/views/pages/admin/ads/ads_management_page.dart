import 'package:boombet_app/views/pages/admin/ads/ad_management_view.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class AdsManagementPage extends StatelessWidget {
  const AdsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ResponsiveWrapper(
        maxWidth: 480,
        constrainOnWeb: true,
        child: AdManagementView(),
      ),
    );
  }
}
