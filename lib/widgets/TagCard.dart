import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';

class TagCard extends StatelessWidget {
  final Tag value;
  final bool? removable;
  final Function? onRemove;

  const TagCard({super.key, required this.value, this.removable, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Container(
        padding: EdgeInsets.all(4),
        child: Text(
          value.tag_name,
        ),
      ),
    );
  }
}