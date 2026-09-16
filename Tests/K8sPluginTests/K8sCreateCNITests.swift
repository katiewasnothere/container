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
import Foundation
import Testing

@testable import ContainerK8s

// MARK: - K8sCreate flag parsing

@Suite("K8sCreate --cni flag")
struct K8sCreateCNIFlagTests {
    @Test func cniDefaultsToNilWhenNotProvided() throws {
        let command = try K8sCreate.parse([])
        #expect(command.cni == nil)
    }

    @Test func cniCapturesProvidedPath() throws {
        let command = try K8sCreate.parse(["--cni", "/tmp/my-cni.yaml"])
        #expect(command.cni == "/tmp/my-cni.yaml")
    }

    @Test func cniAcceptsNone() throws {
        let command = try K8sCreate.parse(["--cni", "none"])
        #expect(command.cni == "none")
    }
}

// MARK: - CNISelection.resolve

@Suite("CNISelection.resolve")
struct CNISelectionResolveTests {
    @Test func nilResolvesToKindnet() throws {
        #expect(try CNISelection.resolve(nil) == .kindnet)
    }

    @Test func noneResolvesToNone() throws {
        #expect(try CNISelection.resolve("none") == .none)
    }

    @Test func noneIsCaseInsensitive() throws {
        #expect(try CNISelection.resolve("None") == .none)
        #expect(try CNISelection.resolve("NONE") == .none)
        #expect(try CNISelection.resolve("nOnE") == .none)
    }

    @Test func existingPathResolvesToManifest() throws {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(UUID().uuidString + ".yaml")
        try "kind: DaemonSet".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(try CNISelection.resolve(url.path) == .manifest(URL(fileURLWithPath: url.path)))
    }

    @Test func missingPathThrowsInvalidArgument() throws {
        let missingPath = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-does-not-exist.yaml").path

        #expect(throws: ContainerizationError.self) {
            _ = try CNISelection.resolve(missingPath)
        }
    }
}
