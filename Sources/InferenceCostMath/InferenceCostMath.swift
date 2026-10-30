import Foundation

/// LLM serving-cost comparison math for Swift: metered API pricing vs
/// self-hosted throughput. All money values are USD; all sizes are tokens.
/// Built for audit-style serving-cost comparisons where every input is
/// explicit and every result is reproducible.
public enum InferenceCostMath {

    /// Price quote from a hosted inference API, USD per 1,000,000 tokens.
    public struct APIPricing: Equatable {
        public let inputPerMillion: Decimal
        public let outputPerMillion: Decimal

        public init(inputPerMillion: Decimal, outputPerMillion: Decimal) {
            self.inputPerMillion = inputPerMillion
            self.outputPerMillion = outputPerMillion
        }
    }

    /// Metered throughput of a deployment, tokens per second.
    public struct Throughput: Equatable {
        public let tokensPerSecond: Decimal

        public init(tokensPerSecond: Decimal) {
            self.tokensPerSecond = tokensPerSecond
        }
    }

    /// Fixed cost of running your own serving hardware.
    public struct ServingProfile: Equatable {
        public let dollarsPerGpuHour: Decimal
        public let gpus: Int

        public init(dollarsPerGpuHour: Decimal, gpus: Int = 1) {
            self.dollarsPerGpuHour = dollarsPerGpuHour
            self.gpus = gpus
        }

        /// Total fleet cost per wall-clock hour.
        public var dollarsPerHour: Decimal { dollarsPerGpuHour * Decimal(gpus) }
    }

    /// Blended USD-per-million price for a workload with the given share of
    /// input tokens (0...1). `inputShare` 0.8 means 80% input, 20% output.
    public static func blendedPricePerMillion(_ pricing: APIPricing,
                                              inputShare: Decimal) -> Decimal {
        precondition(inputShare >= 0 && inputShare <= 1, "inputShare must be in 0...1")
        return inputShare * pricing.inputPerMillion + (1 - inputShare) * pricing.outputPerMillion
    }

    /// Cost of a mixed request run through a metered API.
    public static func apiCost(_ pricing: APIPricing,
                               inputTokens: Decimal,
                               outputTokens: Decimal) -> Decimal {
        (inputTokens / 1_000_000) * pricing.inputPerMillion +
        (outputTokens / 1_000_000) * pricing.outputPerMillion
    }

    /// Cost of serving hardware left running for the given hours.
    public static func selfHostCost(_ profile: ServingProfile, hours: Decimal) -> Decimal {
        profile.dollarsPerHour * hours
    }

    /// Wall-clock hours needed to serve `totalTokens` at the given throughput.
    public static func hoursToServe(totalTokens: Decimal,
                                    throughputTokensPerSecond: Decimal) -> Decimal {
        precondition(throughputTokensPerSecond > 0, "throughput must be positive")
        return (totalTokens / throughputTokensPerSecond) / 3600
    }

    /// Cost of the same workload on self-hosted hardware.
    public static func selfHostCost(totalTokens: Decimal,
                                    throughputTokensPerSecond: Decimal,
                                    profile: ServingProfile) -> Decimal {
        selfHostCost(profile, hours: hoursToServe(totalTokens: totalTokens,
                                                  throughputTokensPerSecond: throughputTokensPerSecond))
    }

    /// The throughput (tokens/sec) at which self-hosted cost per million
    /// tokens equals the API's blended price. Sustained throughput above this
    /// number means owning the hardware is cheaper per token; below it, the
    /// metered API wins. Assumes the fleet runs continuously while serving.
    public static func parityThroughputTokensPerSecond(api pricing: APIPricing,
                                                       inputShare: Decimal,
                                                       profile: ServingProfile) -> Decimal {
        let blended = blendedPricePerMillion(pricing, inputShare: inputShare)
        precondition(blended > 0, "blended price must be positive")
        return (profile.dollarsPerHour * 1_000_000) / (blended * 3600)
    }
}
