import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Password input with a show / hide toggle. With [showStrength] a meter
/// under the field grows and changes color as the password gets stronger.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isNew;
  final bool showStrength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction action;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.isNew = false,
    this.showStrength = false,
    this.validator,
    this.onSubmitted,
    this.action = TextInputAction.done,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          textInputAction: widget.action,
          autofillHints: [
            widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
          ],
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.showStrength ? (_) => setState(() {}) : null,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: AnimatedSwitcher(
                duration: Motion.short,
                child: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  key: ValueKey(_obscure),
                ),
              ),
            ),
          ),
        ),
        if (widget.showStrength)
          _StrengthMeter(password: widget.controller.text),
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final String password;

  const _StrengthMeter({required this.password});

  /// 0 to 4: length, and a mix of lower, upper, digits and symbols.
  static int score(String p) {
    if (p.isEmpty) return 0;
    var s = p.length >= 8 ? 1 : 0;
    if (p.length >= 12) s++;
    if (RegExp(r'[a-z]').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p) && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final s = score(password);
    final status = context.status;
    final (label, color) = switch (s) {
      0 || 1 => ('Weak', status.danger),
      2 => ('Fair', status.warning),
      3 => ('Good', status.info),
      _ => ('Strong', status.success),
    };
    return AnimatedSize(
      duration: Motion.medium,
      curve: Motion.emphasized,
      child: password.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.sm, Gap.xs, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (s + 1) / 5),
                      duration: Motion.medium,
                      curve: Motion.emphasized,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        color: color,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: color),
                  ),
                ],
              ),
            ),
    );
  }
}
