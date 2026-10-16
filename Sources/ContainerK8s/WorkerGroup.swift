//===----------------------------------------------------------------------===//
// Copyright © 2026 Apple Inc. and the container project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

import ContainerPersistence
import ContainerizationError
import Foundation

/// A set of identical worker nodes described by one `--workers` value.
///
/// A value is either a bare number (`3`) or a comma-separated list of `key=value` pairs
/// (`count=2,cpus=4,memory=8g`). Omitted `cpus` and `memory` are computed from the host.
struct WorkerGroup: Equatable {
    var count: UInt
    var cpus: Int64?
    var memory: String?

    init(count: UInt, cpus: Int64? = nil, memory: String? = nil) {
        self.count = count
        self.cpus = cpus
        self.memory = memory
    }

    /// Total number of workers across `groups`, saturating instead of overflowing.
    static func totalCount(of groups: [WorkerGroup]) -> UInt {
        groups.reduce(0) { total, group in
            let (sum, overflow) = total.addingReportingOverflow(group.count)
            return overflow ? UInt.max : sum
        }
    }

    static func parse(_ values: [String]) throws -> [WorkerGroup] {
        try values.map { try parse($0) }
    }

    static func parse(_ value: String) throws -> WorkerGroup {
        if let count = UInt(value) {
            return WorkerGroup(count: count)
        }

        var group = WorkerGroup(count: 1)
        var seen = Set<String>()
        for pair in value.split(separator: ",", omittingEmptySubsequences: false) {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
                throw ContainerizationError(
                    .invalidArgument,
                    message: "invalid worker option '\(pair)' in '\(value)': expected a number or key=value pairs (count, cpus, memory)")
            }
            let key = String(parts[0])
            let val = String(parts[1])
            guard seen.insert(key).inserted else {
                throw ContainerizationError(.invalidArgument, message: "duplicate worker option '\(key)' in '\(value)'")
            }
            switch key {
            case "count":
                guard let count = UInt(val) else {
                    throw ContainerizationError(.invalidArgument, message: "invalid worker count '\(val)' in '\(value)'")
                }
                group.count = count
            case "cpus":
                guard let cpus = Int64(val), cpus > 0 else {
                    throw ContainerizationError(.invalidArgument, message: "invalid worker cpus '\(val)' in '\(value)'")
                }
                group.cpus = cpus
            case "memory":
                _ = try memoryMiB(val, in: value)
                group.memory = val
            default:
                throw ContainerizationError(.invalidArgument, message: "unknown worker option '\(key)' in '\(value)'. Available options: count, cpus, memory")
            }
        }
        return group
    }

    /// Memory in MiB for a size string such as `8g`; rejects zero, negative, and out-of-range sizes.
    static func memoryMiB(_ size: String, in value: String? = nil) throws -> Int64 {
        let context = value.map { " in '\($0)'" } ?? ""
        let mib: Double
        do {
            mib = try Measurement<UnitInformationStorage>.parse(parsing: size).converted(to: .mebibytes).value
        } catch {
            throw ContainerizationError(.invalidArgument, message: "invalid memory '\(size)'\(context): \(error)")
        }
        // Leave headroom so converting to bytes cannot overflow.
        guard mib.isFinite, mib >= 1, mib < Double(Int64.max / (1024 * 1024)) else {
            throw ContainerizationError(.invalidArgument, message: "memory '\(size)'\(context) is out of range")
        }
        return Int64(mib)
    }
}
