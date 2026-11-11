// S-V-13 / T-029
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../core/l10n/l10n.dart';
import 'customers_controller.dart';
import 'customers_page.dart';

class CustomerEditorPage extends ConsumerWidget {
  const CustomerEditorPage({this.id, super.key});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(customersProvider), l = context.l10n;
    final customer = id == null ? null : model.find(id!);
    if (!model.ready || (id != null && customer == null)) {
      return Scaffold(
          appBar: AppBar(title: Text(l.customersEdit)),
          body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(16), children: [
            CustomerFeedback(model: model),
            if (!model.ready && model.failure == null) const SbSkeleton(),
            if (model.ready) Text(l.customersNotFound),
            SbButton(
                label: l.authRetry, onPressed: model.busy ? null : model.load)
          ])));
    }
    return CustomerForm(
        key: ValueKey('${model.owner}:$id'),
        owner: model.owner,
        customer: customer);
  }
}

class CustomerForm extends ConsumerStatefulWidget {
  const CustomerForm({required this.owner, this.customer, super.key});
  final String owner;
  final CustomerResponse? customer;
  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerForm> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  final focuses = <String, FocusNode>{};
  late String payment;
  String text(String name) => fields[name]!.text.trim();
  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    for (final e in {
      'name': c?.name ?? '',
      'mobile': c?.mobile ?? '',
      'email': c?.email ?? '',
      'address': c?.address ?? ''
    }.entries) {
      fields[e.key] = TextEditingController(text: e.value);
      focuses[e.key] = FocusNode();
    }
    payment = c?.preferredPayment.value ?? 'CASH';
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    for (final f in focuses.values) {
      f.dispose();
    }
    super.dispose();
  }

  bool valid(String field) => switch (field) {
        'name' => text(field).isNotEmpty && text(field).length <= 120,
        'mobile' => RegExp(r'^(?:\+91)?[6-9]\d{9}$').hasMatch(text(field)),
        'email' => text(field).isEmpty ||
            (text(field).length <= 254 &&
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text(field))),
        _ => text(field).length <= 500,
      };
  Future<void> save() async {
    if (!form.currentState!.validate()) {
      for (final field in fields.keys) {
        if (!valid(field)) {
          focuses[field]!.requestFocus();
          break;
        }
      }
      return;
    }
    final model = ref.read(customersProvider);
    if (!model.canEdit || model.owner != widget.owner) return;
    await model.save({
      'name': text('name'),
      'mobile': text('mobile'),
      'email': text('email').isEmpty ? null : text('email'),
      'address': text('address'),
      'preferredPayment': payment
    }, id: widget.customer?.id);
    finish(model);
  }

  void finish(CustomersController model) {
    if (mounted &&
        widget.owner == model.owner &&
        model.owner == ref.read(customersProvider).owner &&
        model.failure == null &&
        model.pending == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.customersSaved)));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(customersProvider), l = context.l10n;
    final enabled = model.canEdit && model.owner == widget.owner;
    return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.customer == null ? l.customersAdd : l.customersEdit)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          CustomerFeedback(
              model: model,
              onRetrySaved: () async {
                final current = ref.read(customersProvider);
                await current.retryPending();
                finish(current);
              }),
          Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in fields.keys)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                              key: ValueKey(field),
                              controller: fields[field],
                              focusNode: focuses[field],
                              enabled: enabled &&
                                  (field != 'mobile' ||
                                      widget.customer?.userId == null),
                              maxLength: switch (field) {
                                'name' => 120,
                                'mobile' => 13,
                                'email' => 254,
                                _ => 500
                              },
                              maxLines: field == 'address' ? 3 : 1,
                              keyboardType: switch (field) {
                                'mobile' => TextInputType.phone,
                                'email' => TextInputType.emailAddress,
                                _ => TextInputType.text
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                  labelText: switch (field) {
                                    'name' => l.customersName,
                                    'mobile' => l.customersMobile,
                                    'email' => l.customersEmail,
                                    _ => l.customersAddress
                                  },
                                  helperText: field == 'mobile' &&
                                          widget.customer?.userId != null
                                      ? l.customersLinkedMobile
                                      : null),
                              validator: (_) =>
                                  valid(field) ? null : l.customersInvalid)),
                    DropdownButtonFormField<String>(
                        initialValue: payment,
                        isExpanded: true,
                        decoration:
                            InputDecoration(labelText: l.customersPayment),
                        items: [
                          for (final value in ['CASH', 'UPI', 'BANK', 'WALLET'])
                            DropdownMenuItem(
                                value: value,
                                child: Text(customerPayment(l, value)))
                        ],
                        onChanged: enabled
                            ? (value) => setState(() => payment = value!)
                            : null),
                    const SizedBox(height: 16),
                    SbButton(
                        label: l.customersSave,
                        onPressed: enabled ? save : null),
                    SbButton(
                        label: l.productsCancel,
                        variant: SbButtonVariant.secondary,
                        onPressed: () => context.pop()),
                  ])),
        ])));
  }
}
