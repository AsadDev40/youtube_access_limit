import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.height,
    this.width,
    this.onSaved,
    this.hintText,
    this.focusNode,
    this.onChanged,
    this.controller,
    this.validator,
    this.initialValue,
    this.onTap,
    this.keyboardType,
    this.textAndIconColor,
    this.prefixIconData,
    this.suffixWidget,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.textAlign = TextAlign.left,
    this.hintTextColor = Colors.white,
    this.contentPadding,
    this.enableBorder = true,
    this.hintStyle,
    this.textStyle,
    this.maxLines,
    this.borderRadius,
    this.labelText,
  });

  final double? height;
  final double? width;
  final String? hintText;
  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final TextAlign textAlign;
  final String? Function(String?)? validator;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final Color? textAndIconColor;
  final IconData? prefixIconData;
  final Widget? suffixWidget;
  final Color hintTextColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool enableBorder;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final int? maxLines;
  final double? borderRadius;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.only(left: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 30),
        border: enableBorder ? Border.all(color: colorScheme.primary) : null,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: TextFormField(
        onTap: onTap,
        onSaved: onSaved,
        enabled: enabled,
        readOnly: readOnly,
        textAlign: textAlign,
        initialValue: initialValue,
        maxLines: maxLines ?? 1,
        onChanged: onChanged,
        obscureText: isPassword,
        cursorColor: textAndIconColor ?? colorScheme.primary,
        style: textStyle ?? const TextStyle(color: Colors.black),
        focusNode: focusNode,
        validator: validator,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior
              .auto, // Ensures label floats when the field is focused or has text
          labelText: labelText,
          labelStyle: TextStyle(
            color: textAndIconColor ?? colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          hintText: hintText,
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          hintStyle: hintStyle ??
              textTheme.titleMedium?.copyWith(
                color: hintTextColor,
                fontWeight: FontWeight.bold,
              ),
          prefixIcon: prefixIconData != null
              ? Container(
                  width: 24,
                  height: 24,
                  margin:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                  decoration: BoxDecoration(
                    color: textAndIconColor ?? colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      prefixIconData,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          suffixIcon: suffixWidget,
        ),
      ),
    );
  }
}
