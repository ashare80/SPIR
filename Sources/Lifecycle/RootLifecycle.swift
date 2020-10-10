//
//  Copyright (c) 2020. Adam Share
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CombineExtensions
import Foundation
import SwiftUI

/// The root `Lifecycle` of an application.
public protocol RootLifecycle {
    var rootLifecycleOwner: LifecycleOwner { get }
}

extension RootLifecycle {
    /// Monitoring publisher to view `LifecycleOwner` hierarchy for tests and debugging tools.
    public var childrenChangedPublisher: RelayPublisher<Void> {
        return rootLifecycleOwner.scopeLifecycle.childrenChangedPublisher
    }
}

#if os(macOS)

    extension NSApplicationDelegate where Self: RootLifecycle {
        public func activateRoot() {
            rootLifecycleOwner.activate()
        }

        public func deactivateRoot() {
            rootLifecycleOwner.deactivate()
        }
    }

#elseif os(iOS) || os(tvOS)

    extension UIApplicationDelegate where Self: RootLifecycle {
        public func activateRoot() {
            rootLifecycleOwner.activate()
        }

        public func deactivateRoot() {
            rootLifecycleOwner.deactivate()
        }
    }

    extension UISceneDelegate where Self: RootLifecycle {
        public func activateRoot() {
            rootLifecycleOwner.activate()
        }

        public func deactivateRoot() {
            rootLifecycleOwner.deactivate()
        }
    }

#endif
