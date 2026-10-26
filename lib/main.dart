import 'package:flutter/material.dart';
import 'app.dart';
import 'data/mock_store.dart';

void main() {
  final store = MockStore()..seed();
  runApp(R8App(store: store));
}
