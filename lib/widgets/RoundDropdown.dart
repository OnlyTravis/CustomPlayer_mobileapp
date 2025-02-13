import 'package:flutter/material.dart';

class RoundDropDown extends StatelessWidget {
	final List<String> options;
	final String? value;
	final Color? color;
	final EdgeInsetsGeometry padding; 
	final void Function(String?) onChanged;
	const RoundDropDown({
		super.key, 
		required this.options,
		this.value,
		this.color,
		this.padding = const EdgeInsets.symmetric(horizontal: 10),
		required this.onChanged,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(6.0),
				color: (color == null)?Theme.of(context).colorScheme.inversePrimary:color,
			),
			padding: padding,
			child: DropdownButton(
				value: options.contains(value) ? value : null,
				items: [
					...options.map((string) => DropdownMenuItem<String>(
						value: string,
						child: Text(string),
					))
				],
				onChanged: onChanged,
			),
		);
	}
}