// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_recharge_suppression.dart';

const _tracerName = 'dartastic_otel_libs_recharge';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class RechargeResult {
  const RechargeResult({
    this.itemCount,
    this.totalCount,
    this.apiVersion,
    this.subscriptionStatus,
    this.chargeStatus,
    this.cycleNumber,
    this.intervalUnit,
    this.intervalCount,
    this.amountMinor,
    this.currency,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `total_count`.
  final int? totalCount;

  /// API version, e.g. `2021-11`.
  final String? apiVersion;

  /// `active` / `cancelled` / `expired` / `paused`.
  final String? subscriptionStatus;

  /// `queued` / `success` / `error` / `refunded` / `partially_refunded`
  /// / `skipped`.
  final String? chargeStatus;

  /// Recurring cycle number (the recurring-revenue cohort key).
  final int? cycleNumber;

  /// `day` / `week` / `month`.
  final String? intervalUnit;

  /// Interval count.
  final int? intervalCount;

  /// Charge amount in minor units.
  final int? amountMinor;

  /// ISO 4217.
  final String? currency;

  /// `X-Recharge-Request-Id` (or similar).
  final String? requestId;

  final int? statusCode;
}

class RechargeCallResult<T> {
  const RechargeCallResult({required this.value, this.result});
  final T value;
  final RechargeResult? result;
}

/// Wraps a Recharge API call in a CLIENT span. [operation] is one of
/// `subscriptions.list`, `subscriptions.get`, `subscriptions.create`,
/// `subscriptions.update`, `subscriptions.cancel`,
/// `subscriptions.activate`, `subscriptions.skip`,
/// `subscriptions.set_next_charge_date`, `charges.list`, `charges.get`,
/// `charges.process`, `charges.refund`, `charges.skip`, `orders.list`,
/// `orders.update`, `customers.list`, `customers.create`,
/// `bundle_selections.list`, `webhooks.create`.
Future<T> tracedRecharge<T>({
  required String operation,
  required Future<RechargeCallResult<T>> Function() invoke,
  String? apiVersion,
}) async {
  if (rechargeInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'recharge',
    'rpc.method': operation,
    'recharge.operation': operation,
  };
  if (apiVersion != null) m['recharge.api_version'] = apiVersion;

  final span = _tracer().startSpan(
    'recharge $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'recharge.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalCount != null) {
        extras.add(OTel.attributeInt(
          'recharge.total_count',
          r.result!.totalCount!,
        ));
      }
      if (r.result!.apiVersion != null) {
        extras.add(OTel.attributeString(
          'recharge.api_version',
          r.result!.apiVersion!,
        ));
      }
      if (r.result!.subscriptionStatus != null) {
        extras.add(OTel.attributeString(
          'recharge.subscription.status',
          r.result!.subscriptionStatus!,
        ));
      }
      if (r.result!.chargeStatus != null) {
        extras.add(OTel.attributeString(
          'recharge.charge.status',
          r.result!.chargeStatus!,
        ));
        if (r.result!.chargeStatus == 'error') {
          span.setStatus(
            SpanStatusCode.Error,
            'Recharge charge errored',
          );
        }
      }
      if (r.result!.cycleNumber != null) {
        extras.add(OTel.attributeInt(
          'recharge.cycle_number',
          r.result!.cycleNumber!,
        ));
      }
      if (r.result!.intervalUnit != null) {
        extras.add(OTel.attributeString(
          'recharge.interval.unit',
          r.result!.intervalUnit!,
        ));
      }
      if (r.result!.intervalCount != null) {
        extras.add(OTel.attributeInt(
          'recharge.interval.count',
          r.result!.intervalCount!,
        ));
      }
      if (r.result!.amountMinor != null) {
        extras.add(OTel.attributeInt(
          'recharge.amount.minor',
          r.result!.amountMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'recharge.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'recharge.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Recharge HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
