import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class EmailWidget extends StatelessWidget {
  const EmailWidget({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ShadInput(
      controller: controller,
      placeholder: const Text('Email'),
      leading: Icon(LucideIcons.mail),
      keyboardType: TextInputType.emailAddress,
    );
  }
}
