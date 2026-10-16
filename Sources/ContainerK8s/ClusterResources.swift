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

import Foundation

/// CPU and memory for one node. A `nil` field means "use the single-node default".
struct NodeResources: Equatable {
    var cpus: Int64?
    var memory: String?
}

struct ClusterResources: Equatable {
    var controlPlane: NodeResources
    /// One entry per worker group, in the order the groups were given.
    var workers: [NodeResources]
}

extension K8sHelper {
    private static let workersControlPlaneCPUs: Int64 = 2
    private static let workersControlPlaneMemory = "2g"

    /// Resolves the CPU and memory for the control plane and for each worker group.
    ///
    /// Without workers, `controlPlane` is returned unchanged so the node keeps the single-node
    /// defaults. With workers, the control plane defaults to a fixed size. A worker value that
    /// is not given is left unset, so every such worker gets the same single-node default
    /// whatever the number or mix of workers. Explicit values always win.
    static func clusterResources(controlPlane: NodeResources, groups: [WorkerGroup]) -> ClusterResources {
        guard WorkerGroup.totalCount(of: groups) > 0 else {
            return ClusterResources(controlPlane: controlPlane, workers: [])
        }
        return ClusterResources(
            controlPlane: NodeResources(
                cpus: controlPlane.cpus ?? workersControlPlaneCPUs,
                memory: controlPlane.memory ?? workersControlPlaneMemory),
            workers: groups.map { NodeResources(cpus: $0.cpus, memory: $0.memory) })
    }
}
