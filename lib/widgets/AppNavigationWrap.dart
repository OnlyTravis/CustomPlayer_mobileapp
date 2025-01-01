import 'package:flutter/material.dart';
import 'package:song_player/widgets/NavigationBar.dart';

class AppNavigationWrap extends StatelessWidget {
  final Widget child;
  final String page_name;
  final EdgeInsetsGeometry? padding;
  const AppNavigationWrap({super.key, required this.page_name, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(page_name),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: padding,
              width: double.infinity,
              child: child,
            )
          ),
          CommonNavigationBar()
        ]
      ),
    );
  }
}