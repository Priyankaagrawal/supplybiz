// S-C-02 / T-043: explicit GPS or manual location, never inferred from pincode.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../../core/storage/device_location.dart';
import 'home_controller.dart';

class CustomerLocationPage extends ConsumerWidget {
  const CustomerLocationPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(homeProvider);
    return HomeLocationForm(
        key: ValueKey(model.owner), initial: model.location);
  }
}

class HomeLocationForm extends ConsumerStatefulWidget {
  const HomeLocationForm({this.initial, super.key});
  final HomeLocation? initial;
  @override
  ConsumerState<HomeLocationForm> createState() => _HomeLocationFormState();
}

class _HomeLocationFormState extends ConsumerState<HomeLocationForm> {
  final form = GlobalKey<FormState>(),
      fields = <String, TextEditingController>{};
  bool locating = false, gpsError = false;
  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    for (final e in {
      'address': v?.address ?? '',
      'city': v?.city ?? '',
      'pincode': v?.pincode ?? '',
      'latitude': v?.latitude.toString() ?? '',
      'longitude': v?.longitude.toString() ?? ''
    }.entries) {
      fields[e.key] = TextEditingController(text: e.value);
    }
  }

  @override
  void dispose() {
    if (locating) const DeviceLocation().cancel().catchError((Object _) {});
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> gps() async {
    setState(() {
      locating = true;
      gpsError = false;
    });
    try {
      final p = await const DeviceLocation().current();
      if (mounted) {
        fields['latitude']!.text = '${p.$1}';
        fields['longitude']!.text = '${p.$2}';
      }
    } catch (_) {
      if (mounted) setState(() => gpsError = true);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> choose(HomeLocation location) async {
    final saved = await ref.read(homeProvider).select(location);
    if (!saved || !mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      const CustomerHomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(homeProvider),
        l = context.l10n,
        enabled = !model.busy && !locating;
    final labels = {
      'address': l.homeArea,
      'city': l.onboardingCity,
      'pincode': l.onboardingPincode,
      'latitude': l.onboardingLatitude,
      'longitude': l.onboardingLongitude
    };
    return Scaffold(
        appBar: AppBar(title: Text(l.homeChooseLocation)),
        body: SafeArea(
            child: Form(
                key: form,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Text(l.homeLocationHelp),
                  if (model.busy) const SbSkeleton(),
                  if (model.failure != null)
                    Semantics(
                        liveRegion: true,
                        child: Text(model.failure!.toMessage(l))),
                  for (final entry in labels.entries)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextFormField(
                            key: ValueKey('home-${entry.key}'),
                            controller: fields[entry.key],
                            enabled: enabled,
                            maxLength: entry.key == 'address'
                                ? 200
                                : entry.key == 'city'
                                    ? 100
                                    : entry.key == 'pincode'
                                        ? 6
                                        : 25,
                            decoration: InputDecoration(
                                labelText: entry.value,
                                border: const OutlineInputBorder()),
                            autocorrect: false,
                            keyboardType:
                                {'latitude', 'longitude'}.contains(entry.key)
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true, signed: true)
                                    : entry.key == 'pincode'
                                        ? TextInputType.number
                                        : TextInputType.text,
                            validator: (value) =>
                                validHomeLocationField(entry.key, value ?? '')
                                    ? null
                                    : l.customersInvalid)),
                  if (gpsError)
                    Semantics(liveRegion: true, child: Text(l.areaGpsError)),
                  SbButton(
                      label: l.areaGps,
                      loading: locating,
                      variant: SbButtonVariant.secondary,
                      onPressed: enabled ? gps : null),
                  const SizedBox(height: 12),
                  SbButton(
                      label: l.homeUseLocation,
                      onPressed: enabled
                          ? () {
                              if (form.currentState!.validate()) {
                                choose(HomeLocation(
                                    address: fields['address']!.text.trim(),
                                    city: fields['city']!.text.trim(),
                                    pincode: fields['pincode']!.text.trim(),
                                    latitude: double.parse(
                                        fields['latitude']!.text.trim()),
                                    longitude: double.parse(
                                        fields['longitude']!.text.trim())));
                              }
                            }
                          : null),
                  const SizedBox(height: 20),
                  Semantics(
                      header: true,
                      child: Text(l.homeSavedAddresses,
                          style: Theme.of(context).textTheme.titleLarge)),
                  SbButton(
                      label: l.addressTitle,
                      variant: SbButtonVariant.secondary,
                      onPressed: enabled
                          ? () async {
                              await const CustomerAddressesRoute()
                                  .push<void>(context);
                              if (mounted) await ref.read(homeProvider).load();
                            }
                          : null),
                  for (final row in model.addresses)
                    SbButton(
                        label:
                            '${row.label}: ${row.line1}, ${row.line2}, ${row.city}, ${row.pincode}',
                        variant: SbButtonVariant.secondary,
                        onPressed: enabled
                            ? () => choose(HomeLocation.saved(row))
                            : null),
                ]))));
  }
}

bool validHomeLocationField(String field, String raw) {
  final value = raw.trim();
  if (field == 'latitude' || field == 'longitude') {
    final n = double.tryParse(value);
    return n != null &&
        n.isFinite &&
        n.abs() <= (field == 'latitude' ? 90 : 180);
  }
  if (field == 'pincode') return RegExp(r'^[1-9]\d{5}$').hasMatch(value);
  return value.isNotEmpty && value.length <= (field == 'address' ? 200 : 100);
}
