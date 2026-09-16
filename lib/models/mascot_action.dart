import 'package:flutter/material.dart';

class MascotAction {
  const MascotAction({
    required this.id,
    required this.label,
    required this.hint,
    required this.motionPrompt,
    required this.iconName,
    required this.emoji,
  });

  final String id;
  final String label;
  final String hint;
  final String motionPrompt;
  final String iconName;
  final String emoji;
}

const studioActions = [
  MascotAction(
    id: 'greet',
    label: 'Wave hello',
    hint: 'Say hi to your audience',
    motionPrompt:
        'One quick beat: the mascot faces the camera, smiles, and waves once with one paw or hand. Small bounce, then settle. Cheerful, locked identity.',
    iconName: 'waving_hand',
    emoji: '👋',
  ),
  MascotAction(
    id: 'celebrate',
    label: 'Celebrate',
    hint: 'Cheer when something goes right',
    motionPrompt:
        'One quick beat: the mascot hops once and throws both arms up, then lands. Optional tiny confetti specks. Same character, no morphing.',
    iconName: 'celebration',
    emoji: '🎉',
  ),
  MascotAction(
    id: 'think',
    label: 'Think',
    hint: 'Pause and ponder an idea',
    motionPrompt:
        'One quick beat: the mascot glances up, taps its chin once, and blinks. Then still. Same character, clean studio backdrop.',
    iconName: 'psychology',
    emoji: '💡',
  ),
  MascotAction(
    id: 'present',
    label: 'Present',
    hint: 'Point or gesture toward something',
    motionPrompt:
        'One quick beat: the mascot turns slightly and presents once with an open palm to the right, then holds. Confident, cute, identity locked.',
    iconName: 'front_hand',
    emoji: '✋',
  ),
  MascotAction(
    id: 'peek',
    label: 'Peek',
    hint: 'Take a curious look around',
    motionPrompt:
        'One quick beat: the mascot peeks in from the left, pops into frame with a smile, then holds. Same proportions and colors.',
    iconName: 'visibility',
    emoji: '👀',
  ),
  MascotAction(
    id: 'idle',
    label: 'Idle bounce',
    hint: 'Add a little life while your mascot waits',
    motionPrompt:
        'One quick beat: a small breathing bounce and one blink, then settle. No extra characters, identity locked.',
    iconName: 'self_improvement',
    emoji: '✨',
  ),
];

IconData mascotActionIcon(MascotAction action) {
  return switch (action.iconName) {
    'waving_hand' => Icons.waving_hand_outlined,
    'celebration' => Icons.celebration_outlined,
    'psychology' => Icons.psychology_outlined,
    'front_hand' => Icons.front_hand_outlined,
    'visibility' => Icons.visibility_outlined,
    'self_improvement' => Icons.self_improvement_outlined,
    _ => Icons.movie_outlined,
  };
}

MascotAction? mascotActionById(String? id) {
  if (id == null) return null;
  return studioActions.where((action) => action.id == id).firstOrNull;
}
