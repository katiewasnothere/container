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

import ContainerizationError
import Testing

@testable import ContainerK8s

struct K8sWorkerGroupTests {
    @Test func bareNumberIsCount() throws {
        let groups = try WorkerGroup.parse(["3"])
        #expect(groups == [WorkerGroup(count: 3)])
    }

    @Test func bareZeroIsAllowed() throws {
        let groups = try WorkerGroup.parse(["0"])
        #expect(WorkerGroup.totalCount(of: groups) == 0)
    }

    @Test func keyValueGroup() throws {
        let groups = try WorkerGroup.parse(["count=2,cpus=4,memory=8g"])
        #expect(groups == [WorkerGroup(count: 2, cpus: 4, memory: "8g")])
    }

    @Test func countDefaultsToOne() throws {
        let groups = try WorkerGroup.parse(["cpus=4"])
        #expect(groups == [WorkerGroup(count: 1, cpus: 4, memory: nil)])
    }

    @Test func repeatedFlagProducesOneGroupEach() throws {
        let groups = try WorkerGroup.parse(["count=2,cpus=4", "1", "memory=4g"])
        #expect(groups.count == 3)
        #expect(WorkerGroup.totalCount(of: groups) == 4)
    }

    @Test func noFlagMeansNoGroups() throws {
        #expect(try WorkerGroup.parse([]).isEmpty)
    }

    @Test(arguments: [
        "", "abc", "-1", "count", "count=", "count=x", "count=-1",
        "cpus=0", "cpus=-2", "cpus=x", "memory=0", "memory=x", "memory=9999999999999999999999p",
        "color=red", "count=1,count=2", "count=1,,cpus=2",
    ])
    func invalidValuesAreRejected(_ value: String) {
        #expect(throws: ContainerizationError.self) {
            try WorkerGroup.parse([value])
        }
    }

    @Test func totalCountDoesNotOverflow() throws {
        let groups = [WorkerGroup(count: UInt.max), WorkerGroup(count: 1)]
        #expect(WorkerGroup.totalCount(of: groups) == UInt.max)
    }
}
