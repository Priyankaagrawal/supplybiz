// S-V-30: address/coordinates and radius OR additional pincode coverage (SR-04).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../core/l10n/l10n.dart';
import '../../core/storage/device_location.dart';
import 'service_area_controller.dart';

class ServiceAreaPage extends ConsumerStatefulWidget {
  const ServiceAreaPage({super.key});
  @override
  ConsumerState<ServiceAreaPage> createState() => _ServiceAreaPageState();
}

class _ServiceAreaPageState extends ConsumerState<ServiceAreaPage> {
  final locationForm = GlobalKey<FormState>();
  final coverageForm = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  ServiceAreaController? initialized;
  bool locating = false, gpsError = false;
  String text(String key) => fields[key]!.text.trim();
  @override
  void dispose() {
    if (locating) {
      const DeviceLocation().cancel().catchError((Object _) {});
    }
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget field(String key, String label,
          {int max = 120,
          int min = 1,
          bool coordinate = false,
          bool coverage = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: fields[key],
          enabled: !ref.read(serviceAreaProvider).busy && !locating,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          maxLength: max,
          autocorrect: false,
          keyboardType: coordinate
              ? const TextInputType.numberWithOptions(
                  decimal: true, signed: true)
              : TextInputType.text,
          validator: (raw) {
            final value = (raw ?? '').trim();
            if (coverage) {
              return validCoverage(text('radius'), text('pincodes'))
                  ? null
                  : context.l10n.areaInvalid;
            }
            if (coordinate) {
              final number = double.tryParse(value);
              return number != null &&
                      number.isFinite &&
                      number.abs() <= (key == 'latitude' ? 90 : 180)
                  ? null
                  : context.l10n.onboardingInvalid;
            }
            if (key == 'pincode' && !RegExp(r'^[1-9]\d{5}$').hasMatch(value)) {
              return context.l10n.onboardingInvalid;
            }
            return value.length >= min && value.length <= max
                ? null
                : context.l10n.onboardingInvalid;
          },
        ),
      );

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

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(serviceAreaProvider);
    final l10n = context.l10n;
    final profile = model.profile;
    if (profile != null && initialized != model) {
      initialized = model;
      final initial = <String, String>{
        'address': profile.addressLine ?? '',
        'city': profile.city ?? '',
        'state': profile.state ?? '',
        'pincode': profile.pincode ?? '',
        'latitude': profile.latitude?.toString() ?? '',
        'longitude': profile.longitude?.toString() ?? '',
        'radius': profile.settings.serviceRadiusKm?.toString() ?? '',
        'pincodes': (profile.settings.pincodes ?? []).join(', '),
        ...model.pendingFields,
      };
      for (final c in fields.values) {
        c.dispose();
      }
      fields.clear();
      for (final entry in initial.entries) {
        fields[entry.key] = TextEditingController(text: entry.value);
      }
    }
    final enabled = !model.busy && !locating;
    return Scaffold(
        appBar: AppBar(title: Text(l10n.areaTitle)),
        body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (model.busy) const LinearProgressIndicator(),
                  if (model.failure != null) ...[
                    Semantics(
                        liveRegion: true,
                        child: Text(
                            model.failure!.code == 'REVERIFICATION_REQUIRED'
                                ? l10n.areaReverification
                                : model.failure!.toMessage(l10n))),
                    if (profile == null)
                      SbButton(
                          label: l10n.authRetry,
                          onPressed: enabled ? model.load : null),
                  ],
                  if (model.saved)
                    Semantics(liveRegion: true, child: Text(l10n.areaSaved)),
                  if (profile != null) ...[
                    Text(l10n.areaExplanation),
                    const SizedBox(height: 16),
                    if (profile.businessName == null)
                      Text(l10n.areaBusinessRequired)
                    else
                      Form(
                          key: locationForm,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                    header: true,
                                    child: Text(l10n.areaLocation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge)),
                                field('address', l10n.onboardingAddress,
                                    min: 5, max: 200),
                                field('city', l10n.onboardingCity),
                                field('state', l10n.onboardingState),
                                field('pincode', l10n.onboardingPincode,
                                    max: 6),
                                field('latitude', l10n.onboardingLatitude,
                                    coordinate: true, max: 25),
                                field('longitude', l10n.onboardingLongitude,
                                    coordinate: true, max: 25),
                                if (gpsError)
                                  Semantics(
                                      liveRegion: true,
                                      child: Text(l10n.areaGpsError)),
                                SbButton(
                                    label: l10n.areaGps,
                                    loading: locating,
                                    onPressed: enabled ? gps : null,
                                    variant: SbButtonVariant.secondary),
                                const SizedBox(height: 12),
                                SbButton(
                                    label: l10n.areaSaveLocation,
                                    onPressed: enabled
                                        ? () async {
                                            if (locationForm.currentState!
                                                .validate()) {
                                              await model.saveLocation(
                                                  address: text('address'),
                                                  city: text('city'),
                                                  state: text('state'),
                                                  pincode: text('pincode'),
                                                  latitude: double.parse(
                                                      text('latitude')),
                                                  longitude: double.parse(
                                                      text('longitude')));
                                            }
                                          }
                                        : null),
                              ])),
                    const SizedBox(height: 24),
                    Form(
                        key: coverageForm,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                  header: true,
                                  child: Text(l10n.areaCoverage,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge)),
                              field('radius', l10n.areaRadius,
                                  max: 2, coverage: true),
                              field('pincodes', l10n.areaPincodes,
                                  max: 2000, coverage: true),
                              SbButton(
                                  label: l10n.areaSaveCoverage,
                                  onPressed: enabled
                                      ? () async {
                                          if (coverageForm.currentState!
                                              .validate()) {
                                            await model.saveCoverage(
                                                int.tryParse(text('radius')),
                                                parsePincodes(
                                                    text('pincodes')));
                                          }
                                        }
                                      : null),
                            ])),
                  ],
                ],
              )),
        ));
  }
}
