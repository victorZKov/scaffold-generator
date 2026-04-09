# OpenTelemetry — Observable invariant

Source: `context/governance.md` → invariant 6 (Observable).
{{PROJECT_NAME}}

## Goal

Every backend service emits **structured logs, metrics and traces** via OpenTelemetry from day one. No service ships without it. The CI/CD pipeline gates the merge if instrumentation is missing.

## Two telemetry surfaces

1. **Application telemetry** — what the running service emits (HTTP, DB, queues, business events).
2. **Claude Code telemetry** — what the agent emits while coding (sessions, decisions, costs, tool calls). Configured via managed settings, exported to the same OTel collector.

## Application telemetry — .NET 10

```csharp
// Program.cs
var otel = builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r
        .AddService(serviceName: "{{PROJECT_NAME}}.Api", serviceVersion: "1.0.0")
        .AddAttributes(new Dictionary<string, object>
        {
            ["team"]         = "{{TEAM}}",
            ["cost-center"]  = "{{COST_CENTER}}",
            ["environment"]  = builder.Environment.EnvironmentName
        }))
    .WithTracing(t => t
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddEntityFrameworkCoreInstrumentation()
        .AddNpgsql()
        .AddOtlpExporter())
    .WithMetrics(m => m
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddProcessInstrumentation()
        .AddOtlpExporter())
    .WithLogging(l => l.AddOtlpExporter());
```

Environment variables (set per environment, never hardcoded):

```
OTEL_EXPORTER_OTLP_ENDPOINT={{OTEL_ENDPOINT}}
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_RESOURCE_ATTRIBUTES=team={{TEAM}},cost-center={{COST_CENTER}},deployment.environment=$ASPNETCORE_ENVIRONMENT
OTEL_SERVICE_NAME={{PROJECT_NAME}}.Api
```

## Application telemetry — frontend

```ts
// src/lib/otel.ts
import { WebTracerProvider } from "@opentelemetry/sdk-trace-web";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { Resource } from "@opentelemetry/resources";

const provider = new WebTracerProvider({
  resource: new Resource({
    "service.name": "{{PROJECT_NAME}}.Web",
    "team": "{{TEAM}}",
    "cost-center": "{{COST_CENTER}}",
  }),
});
provider.addSpanProcessor(/* OTLP exporter */);
provider.register();
```

## Claude Code telemetry (managed config)

The managed `.claude/settings.json` (Phase 3 below) sets:

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "{{OTEL_ENDPOINT}}",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_RESOURCE_ATTRIBUTES": "team={{TEAM}},cost-center={{COST_CENTER}},project={{PROJECT_NAME}}"
  }
}
```

This emits sessions, code edit accept/reject ratios, tool execution outcomes and token consumption, segmented by team and cost-center.

## What to dashboard

| Dashboard         | Source           | Audience       |
|-------------------|------------------|----------------|
| Service health    | App OTel         | On-call        |
| Latency / errors  | App OTel         | Engineering    |
| Claude usage/cost | Claude OTel      | Engineering mgmt |
| Accept/reject     | Claude OTel      | Engineering mgmt |
| Cost-center spend | Both, joined     | FinOps         |

## CI/CD enforcement

The governance pipeline grep-asserts that:
- Every backend service has `AddOpenTelemetry` (or equivalent) in startup
- Every frontend has an OTel provider initialization
- Required resource attributes are present (team, cost-center)

A PR adding a service without OTel is blocked.
