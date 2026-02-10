import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final bool showShadow;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.showShadow = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelLarge.copyWith(
              color: AppThemeColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Container(
          decoration: widget.showShadow
              ? BoxDecoration(
                  borderRadius: AppRadius.mdRadius,
                  boxShadow: AppShadows.small,
                )
              : null,
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: _obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            textCapitalization: widget.textCapitalization,
            focusNode: widget.focusNode,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppThemeColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : widget.suffixIcon,
              filled: true,
              fillColor: widget.enabled ? Colors.white : AppThemeColors.shimmer,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

/// Search TextField with shadow
class CustomSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool autofocus;

  const CustomSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: AppShadows.medium,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        autofocus: autofocus,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: hint ?? 'Cari...',
          prefixIcon: const Icon(
            Icons.search,
            color: AppThemeColors.textSecondary,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
        ),
      ),
    );
  }
}
