import 'package:boombet_app/views/pages/admin/raffles/raffles_management_view.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';

class RafflesManagementPage extends StatelessWidget {
  const RafflesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Sorteos', showBackButton: true),
      body: const RafflesManagementView(),
    );
  }
}
