
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

  void showToast(BuildContext context, String title, String description,
      ToastificationType type) {
    toastification.show(
      context: context,
      type: type,
      title: Text(title),
      description: Text(description),
      primaryColor: Colors.white,
      autoCloseDuration: const Duration(seconds: 3),
      progressBarTheme: ProgressIndicatorThemeData(
        color: type == ToastificationType.success
            ? Colors.green
            : type == ToastificationType.info
                ? Colors.blue
                : type == ToastificationType.warning
                    ? Colors.orange
                    : Colors.red,
      ),
      showProgressBar: true,
      backgroundColor: type == ToastificationType.success
          ? Colors.green
          : type == ToastificationType.info
              ? Colors.blue
              : type == ToastificationType.warning
                  ? Colors.orange
                  : Colors.red,
      foregroundColor: Colors.white,
      icon:type == ToastificationType.success
          ?  Icon(Icons.check)
          : type == ToastificationType.info
              ?  Icon(Icons.info)
              : type == ToastificationType.warning
                  ?  Icon(Icons.warning)
                  :  Icon(Icons.close)
    );
  }