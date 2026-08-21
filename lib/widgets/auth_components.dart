import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A premium, glass-free card with a white background, rounded corners,
/// dual-layer soft shadow, and interactive scale-up on hover.
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color borderColor;
  final Color hoverBorderColor;
  final double scaleOnHover;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor = const Color(0xffe2e8f0), // Slate 200
    this.hoverBorderColor = const Color(0xff2563eb), // Brand Blue
    this.scaleOnHover = 1.015,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(32.0),
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scaleByDouble(_isHovered ? widget.scaleOnHover : 1.0, _isHovered ? widget.scaleOnHover : 1.0, 1.0, 1.0),
          transformAlignment: Alignment.center,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isHovered ? widget.hoverBorderColor : widget.borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? Colors.black.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 28 : 20,
                offset: Offset(0, _isHovered ? 12 : 8),
              ),
              BoxShadow(
                color: const Color(0xff2563eb).withValues(alpha: _isHovered ? 0.04 : 0.01),
                blurRadius: _isHovered ? 40 : 30,
                offset: Offset(0, _isHovered ? 16 : 12),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A premium full-width button styled with a blue-to-indigo gradient
/// that scales up slightly and deepens its shadow on hover.
class GradientHoverButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final IconData? icon;
  final bool loading;

  const GradientHoverButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors = const [Color(0xff2563eb), Color(0xff2563eb)], // Solid brand blue by default
    this.icon,
    this.loading = false,
  });

  @override
  State<GradientHoverButton> createState() => _GradientHoverButtonState();
}

class _GradientHoverButtonState extends State<GradientHoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.loading;

    return MouseRegion(
      onEnter: (_) => isEnabled ? setState(() => _isHovered = true) : null,
      onExit: (_) => isEnabled ? setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scaleByDouble(_isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0, 1.0, 1.0),
        transformAlignment: Alignment.center,
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: isEnabled
                ? (_isHovered
                    ? [const Color(0xff3b82f6), const Color(0xff2563eb)]
                    : widget.gradientColors)
                : [Colors.grey.shade300, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: widget.gradientColors[0].withValues(alpha: _isHovered ? 0.35 : 0.2),
                    blurRadius: _isHovered ? 16 : 8,
                    offset: Offset(0, _isHovered ? 6 : 3),
                  )
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: EdgeInsets.zero,
          ),
          child: widget.loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (widget.icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(widget.icon, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// A text input field that glows softly upon receiving focus.
class StyledTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onForgotPassword;

  const StyledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onForgotPassword,
  });

  @override
  State<StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<StyledTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.bold, // Bold label
                color: Color(0xff1e293b), // Slate 800 (Dark color)
              ),
            ),
            if (widget.isPassword && widget.onForgotPassword != null)
              GestureDetector(
                onTap: widget.onForgotPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2563eb),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xff2563eb).withValues(alpha: 0.12),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xff0f172a), // Slate 900
              fontSize: 14.5,
            ),
            validator: widget.validator,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color(0xff94a3b8), fontSize: 14),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused ? const Color(0xff2563eb) : const Color(0xff94a3b8),
                size: 20,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? LucideIcons.eye_off : LucideIcons.eye,
                        color: const Color(0xff94a3b8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xfff8fafc), // Matched screenshot input fill
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffe2e8f0)), // Slate 200 (light border)
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffe2e8f0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff2563eb), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A Date Picker text field styled identically to standard input fields.
class DatePickerField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final Function(DateTime) onDateSelected;

  const DatePickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    required this.onDateSelected,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff2563eb),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xff0f172a),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xff1e293b),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xff2563eb).withValues(alpha: 0.12),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            readOnly: true,
            onTap: () => _selectDate(context),
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xff0f172a),
              fontSize: 14.5,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color(0xff94a3b8), fontSize: 14),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused ? const Color(0xff2563eb) : const Color(0xff94a3b8),
                size: 20,
              ),
              suffixIcon: const Icon(LucideIcons.calendar, color: Color(0xff94a3b8), size: 20),
              filled: true,
              fillColor: const Color(0xfff8fafc),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffe2e8f0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffe2e8f0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff2563eb), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A Dropdown field styled identically to standard input fields.
class StyledDropdownField extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final IconData prefixIcon;
  final ValueChanged<String?> onChanged;

  const StyledDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.prefixIcon,
    required this.onChanged,
  });

  @override
  State<StyledDropdownField> createState() => _StyledDropdownFieldState();
}

class _StyledDropdownFieldState extends State<StyledDropdownField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xff1e293b),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xff2563eb).withValues(alpha: 0.12),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: widget.value,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xff0f172a),
              fontSize: 14.5,
            ),
            dropdownColor: Colors.white,
            icon: const Icon(LucideIcons.chevron_down, color: Color(0xff94a3b8), size: 18),
            decoration: InputDecoration(
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused ? const Color(0xff2563eb) : const Color(0xff94a3b8),
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xfff8fafc),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffe2e8f0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffe2e8f0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff2563eb), width: 1.5),
              ),
            ),
            items: widget.items.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
