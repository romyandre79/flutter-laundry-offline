import 'package:flutter/material.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';

enum ButtonSize { small, medium, large }

enum ButtonVariant { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final ButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final bool iconTrailing;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.iconTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = _getHeight();
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.primary
                    ? Colors.white
                    : AppThemeColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !iconTrailing) ...[
                Icon(icon, size: _getIconSize()),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(text, style: textStyle),
              if (icon != null && iconTrailing) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, size: _getIconSize()),
              ],
            ],
          );

    switch (variant) {
      case ButtonVariant.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: buttonHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: onPressed != null && !isLoading
                  ? AppThemeColors.primaryGradient
                  : null,
              color: onPressed == null || isLoading
                  ? AppThemeColors.disabled
                  : null,
              borderRadius: AppRadius.mdRadius,
              boxShadow: onPressed != null && !isLoading
                  ? AppShadows.purple
                  : null,
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: padding,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
              ),
              child: child,
            ),
          ),
        );

      case ButtonVariant.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.primarySurface,
              foregroundColor: AppThemeColors.primary,
              elevation: 0,
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdRadius,
              ),
            ),
            child: child,
          ),
        );

      case ButtonVariant.outline:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppThemeColors.primary,
              side: BorderSide(
                color: onPressed != null
                    ? AppThemeColors.primary
                    : AppThemeColors.disabled,
              ),
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdRadius,
              ),
            ),
            child: child,
          ),
        );

      case ButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppThemeColors.primary,
            padding: padding,
          ),
          child: child,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  TextStyle _getTextStyle() {
    final baseStyle = variant == ButtonVariant.primary
        ? AppTypography.button
        : AppTypography.button.copyWith(color: AppThemeColors.primary);

    switch (size) {
      case ButtonSize.small:
        return baseStyle.copyWith(fontSize: 12);
      case ButtonSize.medium:
        return baseStyle.copyWith(fontSize: 14);
      case ButtonSize.large:
        return baseStyle.copyWith(fontSize: 16);
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

/// Icon Button with background
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppThemeColors.primarySurface,
        borderRadius: AppRadius.mdRadius,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor ?? AppThemeColors.primary,
          size: size * 0.5,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
