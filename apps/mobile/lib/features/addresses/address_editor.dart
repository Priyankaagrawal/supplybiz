// S-C-29 / T-047: manual coordinates with optional Android GPS.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../../core/storage/device_location.dart';
import 'addresses_controller.dart';
import 'addresses_page.dart';

class AddressEditorPage extends ConsumerWidget {
  const AddressEditorPage({this.id, super.key});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(addressesProvider), l = context.l10n;
    final row = id == null ? null : model.find(id!);
    if (!model.ready || (id != null && row == null)) {
      return Scaffold(
          appBar: AppBar(title: Text(l.addressEdit)),
          body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(16), children: [
            AddressFeedback(model: model),
            if (model.ready) Text(l.networkNotFound),
            SbButton(
                label: l.authRetry, onPressed: model.busy ? null : model.load)
          ])));
    }
    return AddressForm(key: ValueKey('${model.owner}:$id'), row: row);
  }
}

class AddressForm extends ConsumerStatefulWidget {
  const AddressForm({this.row, super.key});
  final AddressResponse? row;
  @override
  ConsumerState<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<AddressForm> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  bool locating = false, gpsError = false;
  late bool isDefault;
  String text(String name) => fields[name]!.text.trim();
  @override
  void initState() {
    super.initState();
    final row = widget.row;
    for (final e in {
      'label': row?.label ?? '',
      'line1': row?.line1 ?? '',
      'line2': row?.line2 ?? '',
      'landmark': row?.landmark ?? '',
      'city': row?.city ?? '',
      'state': row?.state ?? '',
      'pincode': row?.pincode ?? '',
      'latitude': row?.latitude.toString() ?? '',
      'longitude': row?.longitude.toString() ?? ''
    }.entries) {
      fields[e.key] = TextEditingController(text: e.value);
    }
    isDefault = row?.isDefault ?? false;
  }

  @override
  void dispose() {
    if (locating) const DeviceLocation().cancel().catchError((Object _) {});
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> gps() async {
    setState(() {
      locating = true;
      gpsError = false;
    });
    try {
      final point = await const DeviceLocation().current();
      if (mounted) {
        fields['latitude']!.text = '${point.$1}';
        fields['longitude']!.text = '${point.$2}';
      }
    } catch (_) {
      if (mounted) setState(() => gpsError = true);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  void backToAddresses() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      const CustomerAddressesRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(addressesProvider), l = context.l10n;
    final enabled = model.canEdit && !locating;
    final labels = {
      'label': l.addressLabel,
      'line1': l.addressHouse,
      'line2': l.addressArea,
      'landmark': l.addressLandmark,
      'city': l.onboardingCity,
      'state': l.onboardingState,
      'pincode': l.onboardingPincode,
      'latitude': l.onboardingLatitude,
      'longitude': l.onboardingLongitude
    };
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.row == null ? l.addressAdd : l.addressEdit)),
        body: SafeArea(
            child: Form(
                key: form,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  AddressFeedback(
                      model: model,
                      onRetrySaved: () async {
                        await model.retryPending();
                        if (model.completed) backToAddresses();
                      }),
                  SbButton(
                      label: l.authRetry,
                      variant: SbButtonVariant.secondary,
                      onPressed: model.busy || locating ? null : model.load),
                  for (final entry in labels.entries)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextFormField(
                            key: ValueKey('address-${entry.key}'),
                            controller: fields[entry.key],
                            enabled: enabled,
                            decoration: InputDecoration(
                                labelText: entry.value,
                                border: const OutlineInputBorder()),
                            autocorrect: false,
                            minLines: 1,
                            maxLines: 2,
                            maxLength: addressMax(entry.key),
                            keyboardType:
                                {'latitude', 'longitude'}.contains(entry.key)
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true, signed: true)
                                    : entry.key == 'pincode'
                                        ? TextInputType.number
                                        : TextInputType.text,
                            validator: (value) =>
                                validAddressField(entry.key, value ?? '')
                                    ? null
                                    : l.customersInvalid)),
                  if (gpsError)
                    Semantics(liveRegion: true, child: Text(l.areaGpsError)),
                  SbButton(
                      label: l.areaGps,
                      loading: locating,
                      variant: SbButtonVariant.secondary,
                      onPressed: enabled ? gps : null),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.addressMakeDefault),
                      value: isDefault,
                      onChanged: enabled && widget.row?.isDefault != true
                          ? (v) => setState(() => isDefault = v ?? false)
                          : null),
                  SbButton(
                      label: l.addressSave,
                      onPressed: enabled
                          ? () async {
                              if (!form.currentState!.validate()) return;
                              final saved = await model.save(
                                  AddressInput(
                                      label: text('label'),
                                      line1: text('line1'),
                                      line2: text('line2'),
                                      landmark: text('landmark'),
                                      city: text('city'),
                                      state: text('state'),
                                      pincode: text('pincode'),
                                      latitude: double.parse(text('latitude')),
                                      longitude:
                                          double.parse(text('longitude')),
                                      isDefault: isDefault),
                                  id: widget.row?.id);
                              if (saved) backToAddresses();
                            }
                          : null),
                ]))));
  }
}

int addressMax(String name) => switch (name) {
      'label' => 50,
      'line1' || 'line2' || 'landmark' => 200,
      'city' || 'state' => 100,
      'pincode' => 6,
      _ => 25
    };
bool validAddressField(String name, String raw) {
  final value = raw.trim();
  if (name == 'latitude' || name == 'longitude') {
    final number = double.tryParse(value);
    return number != null &&
        number.isFinite &&
        number.abs() <= (name == 'latitude' ? 90 : 180);
  }
  if (name == 'pincode') return RegExp(r'^[1-9]\d{5}$').hasMatch(value);
  return value.length <= addressMax(name) &&
      (name == 'landmark' || value.isNotEmpty);
}
