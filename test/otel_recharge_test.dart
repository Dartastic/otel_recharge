// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_recharge/otel_recharge.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_recharge-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('charges.process records cycle + interval + amount', () async {
    await tracedRecharge<String>(
      operation: 'charges.process',
      apiVersion: '2021-11',
      invoke: () async => const RechargeCallResult(
        value: 'ok',
        result: RechargeResult(
          apiVersion: '2021-11',
          subscriptionStatus: 'active',
          chargeStatus: 'success',
          cycleNumber: 7,
          intervalUnit: 'month',
          intervalCount: 1,
          amountMinor: 4995,
          currency: 'USD',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('recharge charges.process')!);
    expect(a['recharge.api_version'], '2021-11');
    expect(a['recharge.subscription.status'], 'active');
    expect(a['recharge.charge.status'], 'success');
    expect(a['recharge.cycle_number'], 7);
    expect(a['recharge.interval.unit'], 'month');
    expect(a['recharge.amount.minor'], 4995);
  });

  test('errored charge sets span error', () async {
    await tracedRecharge<String>(
      operation: 'charges.process',
      invoke: () async => const RechargeCallResult(
        value: 'ok',
        result: RechargeResult(chargeStatus: 'error'),
      ),
    );
    expect(
      spans.findSpanByName('recharge charges.process')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutRechargeInstrumentationAsync(() async {
      await tracedRecharge<String>(
        operation: 'subscriptions.list',
        invoke: () async => const RechargeCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('recharge '), isEmpty);
  });
}
