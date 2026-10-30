# InferenceCostMath

Swift math for LLM serving-cost comparisons: metered API pricing vs
self-hosted throughput, blended input/output rates, and the parity
throughput where owning the GPUs starts winning per token.

Pure Foundation, no dependencies, `Decimal` throughout so cost audits do
not inherit floating-point drift.

## What is inside

- `APIPricing` - per-million input/output price quote from a hosted API
- `Throughput` / `ServingProfile` - metered rate and hardware cost model
- `apiCost` - cost of a mixed input/output workload on the API
- `selfHostCost` - cost of the same workload on owned hardware
- `blendedPricePerMillion` - one number for a known input/output mix
- `parityThroughputTokensPerSecond` - the tokens/sec where self-hosting
  matches the API; sustained throughput above it means the hardware wins

## Example

```swift
let pricing = APIPricing(inputPerMillion: 3, outputPerMillion: 15)
let blended = InferenceCostMath.blendedPricePerMillion(pricing, inputShare: 0.8)
// 5.4 USD per 1M mixed tokens

let profile = ServingProfile(dollarsPerGpuHour: 2.5, gpus: 8)
let parity = InferenceCostMath.parityThroughputTokensPerSecond(
    api: pricing, inputShare: 0.8, profile: profile)
// ~4115 tokens/sec: serve faster than this and self-hosting is cheaper per token
```

## Installation

CocoaPods:

```ruby
pod 'InferenceCostMath', '~> 0.1'
```

Swift Package Manager: point at this repository, tag `0.1.0`.

## About

Built by the PastAGI team. [PastAGI](https://www.pastagi.com) publishes
audited serving-cost math for LLM builders - price audits, throughput
economics, and verifiable per-token comparisons. This pod is the same
serving math, packaged for Swift apps.

MIT licensed.
