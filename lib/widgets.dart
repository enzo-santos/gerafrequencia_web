import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;

class FieldItem extends ffb.FieldItem {
  const FieldItem({
    super.key,
    super.isEnabled,
    super.alignment,
    super.onTap,
    required super.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(child: super.build(context));
  }
}

class Button extends StatelessWidget {
  final String label;
  final Color color;
  final void Function() onPressed;

  const Button({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}
