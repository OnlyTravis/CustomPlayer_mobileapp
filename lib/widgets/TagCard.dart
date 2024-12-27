import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';

class TagCard extends StatelessWidget {
  final Tag value;
  final bool? removable;
  final Function? onRemove;
  final Function? onTap;

  const TagCard({super.key, required this.value, this.removable, this.onRemove, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap!(value),
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              child: Text(value.tag_name,),
            ),
            Container(
              padding: EdgeInsets.all(6),
              color: Theme.of(context).colorScheme.surfaceDim,
              child: Text(value.tag_count.toString(),),
            ),
          ],
        ),
      ),
    );
  }
}