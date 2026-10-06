import 'package:flutter/widgets.dart';

class WizardNPC extends StatelessWidget {
  const WizardNPC({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/wiz.gif',
      fit: BoxFit.contain,
    );
  }
}