import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';

class TagCard extends StatelessWidget {
  final Tag value;
  final bool tapable;
  final bool removable;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const TagCard({super.key, required this.value, this.tapable = false, this.removable = false, this.onRemove, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tapable?onTap:null,
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (removable) GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.cancel),
            ),
            Container(
              padding: EdgeInsets.all(6),
              child: Text(value.tag_name),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              color: Theme.of(context).colorScheme.surfaceDim,
              child: Text(value.tag_count.toString(),),
            ),
          ],
        ),
      ),
    );
  }
}