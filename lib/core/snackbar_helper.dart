import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Единый хелпер для показа красивых современных уведомлений
class SnackbarHelper {
  static void success(String message) {
    _show(message, Colors.green.shade600, Icons.check_circle_rounded);
  }

  static void error(String message) {
    _show(message, Colors.red.shade600, Icons.error_rounded);
  }

  static void info(String message) {
    _show(message, Colors.blue.shade600, Icons.info_rounded);
  }

  static void show(String message, Color color) {
    _show(message, color, Icons.notifications_rounded);
  }

  static void _show(String message, Color color, IconData icon) {
    if (!Get.isSnackbarOpen) {
      Get.showSnackbar(
        GetSnackBar(
          messageText: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.only(top: 8, right: 16, left: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          borderRadius: 12,
          backgroundColor: color,
          barBlur: 0,
          isDismissible: true,
          snackStyle: SnackStyle.FLOATING,
          boxShadows: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      );
    }
  }
}
