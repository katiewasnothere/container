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

import Testing

@testable import ContainerK8s

struct K8sClusterResourcesTests {
    private func resources(cpus: Int64? = nil, memory: String? = nil, groups: [WorkerGroup]) -> ClusterResources {
        K8sHelper.clusterResources(controlPlane: NodeResources(cpus: cpus, memory: memory), groups: groups)
    }

    @Test func noWorkersLeavesControlPlaneToExistingDefaults() {
        let r = resources(groups: [])
        #expect(r.controlPlane == NodeResources(cpus: nil, memory: nil))
        #expect(r.workers.isEmpty)
    }

    @Test func noWorkersKeepsExplicitControlPlaneValues() {
        let r = resources(cpus: 6, memory: "12g", groups: [WorkerGroup(count: 0)])
        #expect(r.controlPlane == NodeResources(cpus: 6, memory: "12g"))
    }

    @Test func controlPlaneIsFixedWhenThereAreWorkers() {
        let r = resources(groups: [WorkerGroup(count: 3)])
        #expect(r.controlPlane == NodeResources(cpus: 2, memory: "2g"))
    }

    @Test func explicitControlPlaneValuesWinWhenThereAreWorkers() {
        let r = resources(cpus: 4, memory: "8g", groups: [WorkerGroup(count: 1)])
        #expect(r.controlPlane == NodeResources(cpus: 4, memory: "8g"))
    }

    @Test func defaultWorkersAreTheSameWhateverTheCountOrMix() {
        let one = resources(groups: [WorkerGroup(count: 1)])
        let five = resources(groups: [WorkerGroup(count: 5)])
        let mixed = resources(groups: [WorkerGroup(count: 2), WorkerGroup(count: 4)])
        #expect(one.workers == [NodeResources(cpus: nil, memory: nil)])
        #expect(five.workers == one.workers)
        #expect(mixed.workers == [NodeResources(cpus: nil, memory: nil), NodeResources(cpus: nil, memory: nil)])
    }

    @Test func explicitGroupValuesApplyToThatGroupOnly() {
        let r = resources(groups: [WorkerGroup(count: 1, cpus: 8, memory: "16g"), WorkerGroup(count: 1), WorkerGroup(count: 1, cpus: 4)])
        #expect(r.workers[0] == NodeResources(cpus: 8, memory: "16g"))
        #expect(r.workers[1] == NodeResources(cpus: nil, memory: nil))
        #expect(r.workers[2] == NodeResources(cpus: 4, memory: nil))
    }
}
