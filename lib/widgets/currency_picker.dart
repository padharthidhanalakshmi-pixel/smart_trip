import 'package:flutter/material.dart';

import '../services/currency_service.dart';

Future<String?> pickCurrency(BuildContext context, {required String current, List<String> extra = const []}) {
  final codes = <String>{...extra.where((c) => c.isNotEmpty), ...kCurrencies}.toList();
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: ListView(
          children: [
            for (final code in codes)
              ListTile(
                leading: SizedBox(width: 44, child: Text(currencySymbol(code).trim(), textAlign: TextAlign.center)),
                title: Text(code),
                trailing: code == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, code),
              ),
          ],
        ),
      ),
    ),
  );
}
