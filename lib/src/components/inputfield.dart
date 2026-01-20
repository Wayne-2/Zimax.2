// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InputField extends StatelessWidget {
  final bool obscureText;
  final String hintText;
  final TextEditingController controller;
  const InputField({
    super.key,
    required this.obscureText,
    required this.hintText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: TextFormField(
        controller: controller,
        // keyboardType: keyboardType,
        obscureText: obscureText,
        cursorHeight: 20,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).cardColor,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(fontSize: 13),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18.0,
            horizontal: 12.0,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.8,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class Dropdown extends StatefulWidget {
  final String hint;
  final List<String> items;

  const Dropdown({super.key, required this.hint, required this.items});

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            hint: Text(widget.hint),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color.fromARGB(239, 0, 0, 0),
            ),
            isExpanded: true,
            borderRadius: BorderRadius.circular(14),
            items: widget.items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedValue = value;
              });
            },
          ),
        ),
      ),
    );
  }
}
