final RegExp emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateEmail(String value) {
  if (value.isEmpty) return 'Email is required';
  if (!emailPattern.hasMatch(value)) return 'Enter a valid email';
  return null;
}
