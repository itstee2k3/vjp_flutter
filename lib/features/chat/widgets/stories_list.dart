import 'package:flutter/material.dart';
import '../../../data/models/story.dart';

class StoriesList extends StatelessWidget {
  final List<Story> stories;
  final Function(Story) onStoryTap;

  const StoriesList({
    Key? key,
    required this.stories,
    required this.onStoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 60,
              child: GestureDetector(
                onTap: () => onStoryTap(story),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(story.avatarUrl),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        story.username,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 