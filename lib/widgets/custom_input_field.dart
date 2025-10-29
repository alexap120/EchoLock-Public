import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final IconData? optionalIcon;
  final VoidCallback? onOptionalIconTap;
  final TextInputType keyboardType;
  final Color focusColor;
  final int? minLines;
  final int? maxLines;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.optionalIcon,
    this.onOptionalIconTap,
    this.keyboardType = TextInputType.text,
    this.focusColor = const Color(0xFF328E6E),
    this.minLines,
    this.maxLines,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isValidEmail = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onInputChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onInputChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (!_isFocused && widget.keyboardType == TextInputType.emailAddress) {
        _validateEmail(widget.controller.text);
      }
    });
  }

  void _onInputChange() {
    if (widget.keyboardType == TextInputType.emailAddress) {
      _validateEmail(widget.controller.text);
    }
  }

  void _validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    setState(() {
      if (value.isEmpty || emailRegex.hasMatch(value)) {
        _isValidEmail = true;
        _errorMessage = null;
      } else {
        _isValidEmail = false;
        _errorMessage = 'Please enter an email address in the format';
      }
    });
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          elevation: _isFocused ? 4.0 : 0.0,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.grey.withOpacity(0.5),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            minLines: widget.minLines,
            maxLines: widget.maxLines ?? (widget.obscureText ? 1 : 1),
            decoration: InputDecoration(
              labelText: widget.label,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              suffixIcon: _isFocused && widget.optionalIcon != null
                  ? InkWell(
                onTap: widget.onOptionalIconTap,
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  widget.optionalIcon,
                  color: Colors.grey[600],
                ),
              )
                  : null,
              enabledBorder: _buildBorder(_isValidEmail ? Colors.grey : Colors.red),
              focusedBorder: _buildBorder(
                  _isValidEmail ? widget.focusColor : Colors.red,
                  width: 1.5),
              border: _buildBorder(Colors.grey),
              floatingLabelStyle: TextStyle(
                  color: _isFocused
                      ? (_isValidEmail ? widget.focusColor : Colors.red)
                      : Colors.grey[600]),
              errorText: !_isValidEmail ? _errorMessage : null,
            ),
          ),
        ),
        if (!_isValidEmail)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            child: Text(
              "example@domain.com" ?? '',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}