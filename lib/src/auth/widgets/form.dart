import 'package:flutter/material.dart';

typedef AuthButton = (String label, VoidCallback callback);

class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.title,
    required this.children,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    this.footer,
    this.error,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;
  final String? error;
  final AuthButton primary, secondary, tertiary;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 20);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: fonts.displaySmall,
                ),
              ),
            ],
          ),
          gap,
          ...children,
          if (error != null) ...[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Error signing in: $error',
                textAlign: TextAlign.center,
                style: fonts.bodyMedium?.copyWith(color: colors.error),
              ),
            ),
          ],
          gap,
          Row(
            children: [
              FilledButton(
                onPressed: primary.$2,
                child: Text(primary.$1),
              ),
              const Spacer(),
              TextButton(
                onPressed: secondary.$2,
                child: Text(secondary.$1),
              ),
            ],
          ),
          gap,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: tertiary.$2,
                  child: Text(tertiary.$1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
