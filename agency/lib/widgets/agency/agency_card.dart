import 'package:flutter/material.dart';

class AgencyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const AgencyCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: const Icon(Icons.business),
      ),
    );
  }
}
