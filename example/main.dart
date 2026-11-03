// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_recharge/otel_recharge.dart';

/// Traces Recharge calls with OpenTelemetry.
///
/// `otel_recharge` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Recharge call in
/// [tracedRecharge]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'recharge-example');

  // Wraps a Recharge API call in a CLIENT span.
  final rechargeId = await tracedRecharge<String>(
    operation: 'subscriptions.create',
    apiVersion: '1',
    invoke: () async {
      // Make the Recharge call here, then report what it returned.
      const id = 'recharge_8f3a2c';
      return const RechargeCallResult(
          value: id,
          result: RechargeResult(
              itemCount: 3,
              totalCount: 3,
              apiVersion: '2021-11',
              subscriptionStatus: 'active',
              chargeStatus: 'queued',
              cycleNumber: 1,
              intervalUnit: 'day',
              intervalCount: 3,
              amountMinor: 1999,
              currency: 'usd',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedRecharge subscriptions.create returned $rechargeId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutRechargeInstrumentationAsync.
  await runWithoutRechargeInstrumentationAsync(
    () => tracedRecharge<String>(
      operation: 'subscriptions.create',
      apiVersion: '1',
      invoke: () async {
        const id = 'recharge_8f3a2c';
        return const RechargeCallResult(
            value: id,
            result: RechargeResult(
                itemCount: 3,
                totalCount: 3,
                apiVersion: '2021-11',
                subscriptionStatus: 'active',
                chargeStatus: 'queued',
                cycleNumber: 1,
                intervalUnit: 'day',
                intervalCount: 3,
                amountMinor: 1999,
                currency: 'usd',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
