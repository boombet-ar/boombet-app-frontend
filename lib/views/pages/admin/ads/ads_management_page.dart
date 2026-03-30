import 'package:boombet_app/views/pages/admin/ads/ad_management_view.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';

class AdsManagementPage extends StatelessWidget {
  const AdsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Publicidades', showBackButton: true),
      body: const AdManagementView(),
    );
  }
}
