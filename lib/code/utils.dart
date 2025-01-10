import 'package:flutter/material.dart';

void confirm(BuildContext context, String title, String text, Function onConfirm, Function onCancel) {
  showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Confirm'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel();
          },
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

void alert(BuildContext context, String text, {int duration = 1}) {
  final snack_bar = SnackBar(
    content: Text(text),
    duration: Duration(seconds: duration),
    action: SnackBarAction(
      label: "Dismiss", 
      onPressed: ScaffoldMessenger.of(context).hideCurrentSnackBar
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(snack_bar);
}