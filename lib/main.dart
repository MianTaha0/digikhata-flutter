import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/reminders/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(NotificationService.instance.init());
  runApp(const ProviderScope(child: DigiKhataApp()));
}
