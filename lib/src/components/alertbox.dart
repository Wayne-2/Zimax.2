import 'package:flutter/cupertino.dart';

void showIOSDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text(
          "Allow Notifications?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            "Zimax wants to send you notifications.\n\n"
            "These may include alerts, sounds, and badges.",
            style: TextStyle(
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: false,
            onPressed: () => Navigator.pop(context),
            child: const Text("Don’t Allow"),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Allow"),
          ),
        ],
      );
    },
  );
}