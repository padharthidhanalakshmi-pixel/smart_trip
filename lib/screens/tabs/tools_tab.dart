import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../providers/settings_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/currency_service.dart';
import '../../services/demo_data.dart';
import '../../services/services.dart';
import '../../services/timezone_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/currency_picker.dart';

class ToolsTab extends StatefulWidget {
  const ToolsTab({super.key, required this.trip});

  final Trip trip;

  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> with AutomaticKeepAliveClientMixin {
  late String _from;
  String _to = 'USD';
  final _amount = TextEditingController(text: '1000');
  late final TextEditingController _notes;
  late final TripProvider _provider;
  late bool _demo;
  RatesResult? _rates;
  String? _result;
  String? _error;
  bool _converting = false;
  late Future<Duration> _offset;
  Timer? _tick;
  Timer? _notesDebounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _provider = context.read<TripProvider>();
    _demo = settings.demoMode;
    _from = settings.homeCurrency;
    _to = _from == 'USD' ? 'EUR' : 'USD';
    _notes = TextEditingController(text: widget.trip.notes);
    _loadOffset();
    _resolveDestinationCurrency();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  void _loadOffset() {
    _offset = _demo
        ? Future.value(DemoData.offset(widget.trip.destination))
        : Services.timeZone.offsetFor(widget.trip.destination);
  }

  Future<void> _resolveDestinationCurrency() async {
    final info = await Services.currency.forCountry(widget.trip.destination.countryCode);
    if (!mounted || info == null || info.code == _from) return;
    setState(() => _to = info.code);
  }

  @override
  void dispose() {
    _tick?.cancel();
    if (_notesDebounce?.isActive ?? false) {
      _notesDebounce!.cancel();
      widget.trip.notes = _notes.text;
      _provider.persist();
    }
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    FocusScope.of(context).unfocus();
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (amount == null || amount < 0) {
      setState(() {
        _error = 'Enter a valid amount';
        _result = null;
      });
      return;
    }
    setState(() {
      _converting = true;
      _error = null;
    });
    try {
      final rates = _demo ? DemoData.rates(_from) : await Services.currency.rates(_from);
      final rate = rates.rates[_to];
      if (rate == null) throw AppException('No exchange rate is available for $_from to $_to.');
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _result = '${currencySymbol(_from)}${fmtNumber(amount)} → approximately '
            '${currencySymbol(_to)}${fmtNumber(amount * rate)}';
      });
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _result = null;
        });
      }
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  Widget _currencyButton(String code, ValueChanged<String> onPicked) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      onPressed: () async {
        final picked = await pickCurrency(context, current: code, extra: [_from, _to]);
        if (picked != null) onPicked(picked);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(code, style: const TextStyle(fontSize: 16)), const Icon(Icons.arrow_drop_down)],
      ),
    );
  }

  Widget _clock(String label, DateTime time, String sub) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(fmtClock(time), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        Text('${fmtWeekday(time)} ${fmtShortDate(time)}, $sub', style: theme.textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final rates = _rates;
    final dest = widget.trip.destination;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Currency converter',
          icon: Icons.currency_exchange,
          trailing: _demo ? const SmallTag('Demo') : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _currencyButton(_from, (c) => setState(() {
                        _from = c;
                        _result = null;
                      }))),
                  IconButton(
                    tooltip: 'Swap currencies',
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => setState(() {
                      final t = _from;
                      _from = _to;
                      _to = t;
                      _result = null;
                    }),
                  ),
                  Expanded(child: _currencyButton(_to, (c) => setState(() {
                        _to = c;
                        _result = null;
                      }))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _convert(),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: currencySymbol(_from),
                  border: const OutlineInputBorder(),
                  errorText: _error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _converting ? null : _convert,
                icon: _converting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_alt),
                label: const Text('Convert'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 14),
                Text(_result!, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 8),
              Text(
                rates == null
                    ? 'Exchange rates are approximate and can change.'
                    : 'Exchange rates are approximate and can change. Source: ${rates.source}'
                        '${rates.updated.isEmpty ? '' : ', updated ${rates.updated}'}.',
                style: small,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Time zone',
          icon: Icons.schedule,
          trailing: _demo ? const SmallTag('Demo') : null,
          child: FutureBuilder<Duration>(
            future: _offset,
            builder: (context, snap) {
              if (snap.hasError) {
                return ErrorPanel(message: friendlyError(snap.error), onRetry: () => setState(_loadOffset));
              }
              final offset = snap.data;
              if (offset == null) return const LoadingPanel(label: 'Getting local time…');
              final info = TimeZoneService.compute(offset);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _clock(dest.name, info.destNow, fmtOffset(info.destOffset))),
                      const SizedBox(width: 12),
                      Expanded(child: _clock('Home (this phone)', info.homeNow, fmtOffset(info.homeOffset))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(info.describe(), style: theme.textTheme.titleSmall),
                  if (_demo) Text('Demo estimate from longitude, not a real time zone.', style: small),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Trip notes',
          icon: Icons.sticky_note_2_outlined,
          child: TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Hotel address, booking numbers, reminders…',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              _notesDebounce?.cancel();
              _notesDebounce = Timer(const Duration(milliseconds: 600), () {
                widget.trip.notes = v;
                _provider.save(widget.trip);
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Text('Notes are saved on this device only.', style: small),
      ],
    );
  }
}
