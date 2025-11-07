import 'dart:math';

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good Morning';
  }
  if (hour < 17) {
    return 'Good Afternoon';
  }
  return 'Good Evening';
}

String getUniqueMessage() {
  final messages = [
    'What can we help you with today?',
    'How can we make your day easier?',
    'Ready for a fresh start?',
    'Let us handle the laundry.',
    'Swift, clean, and delivered to you.',
  ];
  final random = Random();
  return messages[random.nextInt(messages.length)];
}
