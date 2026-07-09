import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ImageUtils {
  static Widget getImage(String? path,
      {double? width, double? height, BoxFit? fit}) {
    if (path == null || path.isEmpty) {
      return _buildPlaceholder(width, height);
    }

    if (kIsWeb) {
      return _buildWebImage(path, width: width, height: height, fit: fit);
    } else {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(width, height),
          );
        } else {
          return _buildPlaceholder(width, height);
        }
      } catch (e) {
        return _buildPlaceholder(width, height);
      }
    }
  }

  static Widget _buildWebImage(String path,
      {double? width, double? height, BoxFit? fit}) {
    try {
      // Если путь начинается с data:image, это base64
      if (path.startsWith('data:image')) {
        try {
          final base64String = path.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(width, height),
          );
        } catch (e) {
          return _buildPlaceholder(width, height);
        }
      }

      // Если путь начинается с http, используем NetworkImage
      if (path.startsWith('http')) {
        return Image.network(
          path,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(width, height),
        );
      }

      return _buildPlaceholder(width, height);
    } catch (e) {
      return _buildPlaceholder(width, height);
    }
  }

  static Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width ?? 80,
      height: height ?? 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.book, size: 40, color: Colors.grey),
    );
  }
}
