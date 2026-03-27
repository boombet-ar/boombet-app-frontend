import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/home/widgets/raffles_content.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';

class RafflesPage extends StatelessWidget {
  const RafflesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderWidget(
            title: 'Sorteos',
            subtitle: 'Participá y ganá premios exclusivos',
            icon: Icons.emoji_events_rounded,
          ),
          const Expanded(
            child: RafflesContent(),
          ),
        ],
      ),
    );
  }
}
