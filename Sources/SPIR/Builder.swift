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

import Foundation
import Lifecycle

/// Type that builds with no added dependencies..
public protocol Buildable: AnyObject {
    /// Return type from build function.
    associatedtype R

    /// Builds a new instance of `R`.
    func build() -> R
}

/// Type erased builder of new `R` instances.
public final class AnyBuilder<R>: ObjectIdentifiable, Buildable {
    private let builder: () -> R

    /// Initializer.
    ///
    /// - parameter builder: The building closure that creates a new instance of `R` on each call to build.
    public init(_ builder: @escaping () -> R) {
        self.builder = builder
    }

    /// Builds a new instance of `R`.
    public func build() -> R {
        return builder()
    }
}

/// Builds a new `Interactable` instance.
public protocol InteractableBuildable: AnyObject {
    /// Builds a new `Interactable` instance.
    func build() -> Interactable
}

/// Builds a new `PresentableInteractable` instance.
public protocol PresentableInteractableBuildable: AnyObject {
    /// Builds a new `PresentableInteractable` instance.
    func build() -> PresentableInteractable
}

extension AnyBuilder: InteractableBuildable where R == Interactable {}
extension AnyBuilder: PresentableInteractableBuildable where R == PresentableInteractable {}

/// Type that builds with a dynamic dependency.
public protocol DynamicBuildable: AnyObject {
    /// Type of dynami dependency the builder needs to create an instance.
    associatedtype DynamicDependency

    /// Return type from build function.
    associatedtype R

    /// Builds a new instance of `R`.
    ///
    /// - parameter dynamicDependency: The dynamic dependency that could not be injected.
    /// - returns: New instance of `R`.
    func build(_ dynamicDependency: DynamicDependency) -> R
}

extension DynamicBuildable {
    /// Wraps with dynamic dependancy to`AnyBuilder<R>` for deferred building.
    ///
    /// - parameter dynamicDependency: The dynamic dependency that could not be injected.
    /// - returns: Wrapped builder of type `AnyBuilder<R>`.
    public func asAnyBuilder(_ dynamicDependency: DynamicDependency) -> AnyBuilder<R> {
        return AnyBuilder { self.build(dynamicDependency) }
    }
}

/// Type erased builder of new `R` instances with a dynamic build time dependency.
public final class AnyDynamicBuilder<DynamicDependency, R>: ObjectIdentifiable, DynamicBuildable {
    private let builder: (DynamicDependency) -> R

    /// Initializer.
    ///
    /// - parameter builder: The building closure that creates a new instance of `R` on each call to build.
    public init(_ builder: @escaping (DynamicDependency) -> R) {
        self.builder = builder
    }

    /// Builds a new instance of `R`.
    ///
    /// - parameter dynamicDependency: The dynamic dependency that could not be injected.
    /// - returns: New instance of `R`.
    public func build(_ dynamicDependency: DynamicDependency) -> R {
        return builder(dynamicDependency)
    }
}

/// Type that builds with no added dependencies..
public protocol CachedBuildable: AnyObject {
    /// Return type from build function.
    associatedtype R

    /// Builds a new instance of `R`.
    func getOrCreate() -> R
}

public protocol WeakCachedBuildable: CachedBuildable {
    var instance: R? { get }
}

public protocol LazyValue: CachedBuildable {
    var value: R { get }
}

extension LazyValue {
    public var value: R {
        return getOrCreate()
    }
}

/// Weakly holds reference to the lazily created value.
public final class WeakCachedBuilder<R: AnyObject>: ObjectIdentifiable, WeakCachedBuildable, LazyValue {

    public weak var instance: R?

    private let builder: () -> R
    private let lock: NSRecursiveLock = NSRecursiveLock()

    /// Initializer.
    ///
    /// - parameter builder: The building closure that creates a new instance of `R` on each call to build.
    public init(_ builder: @escaping () -> R) {
        self.builder = builder
    }

    /// Builds a new instance of `R`.
    public func getOrCreate() -> R {
        lock.lock(); defer { lock.unlock() }

        if let instance = instance {
            return instance
        } else {
            let newInstance = builder()
            instance = newInstance
            return newInstance
        }
    }
}

/// Holds a strong reference to the lazily created value.
public final class CachedBuilder<R>: ObjectIdentifiable, CachedBuildable {

    public var value: R {
        return getOrCreate()
    }

    private let builder: () -> R
    private var instance: R?
    private let lock: NSRecursiveLock = NSRecursiveLock()

    /// Initializer.
    ///
    /// - parameter builder: The building closure that creates a new instance of `R` on each call to build.
    public init(_ builder: @escaping () -> R) {
        self.builder = builder
    }

    /// Builds a new instance of `R`.
    public func getOrCreate() -> R {
        lock.lock(); defer { lock.unlock() }

        if let instance = instance {
            return instance
        } else {
            let newInstance = builder()
            instance = newInstance
            return newInstance
        }
    }
}

/// Builds a new `Interactable` instance.
public protocol LazyInteractable: AnyObject {
    /// Builds a new `Interactable` instance.
    var value: Interactable { get }
}

/// Builds a new `PresentableInteractable` instance.
public protocol LazyPresentableInteractable: AnyObject {
    /// Builds a new `PresentableInteractable` instance.
    var value: PresentableInteractable { get }
}

extension CachedBuilder: InteractableBuildable where R == Interactable {
    public func build() -> Interactable {
        return getOrCreate()
    }
}

extension CachedBuilder: PresentableInteractableBuildable where R == PresentableInteractable {
    public func build() -> PresentableInteractable {
        return getOrCreate()
    }
}

extension CachedBuilder: LazyInteractable where R == Interactable {
    public var value: Interactable {
        return getOrCreate()
    }
}

extension CachedBuilder: LazyPresentableInteractable where R == PresentableInteractable {
    public var value: PresentableInteractable {
        return getOrCreate()
    }
}

extension WeakCachedBuilder: InteractableBuildable where R: Interactable {
    public func build() -> Interactable {
        return getOrCreate()
    }
}

extension WeakCachedBuilder: PresentableInteractableBuildable where R: PresentableInteractable {
    public func build() -> PresentableInteractable {
        return getOrCreate()
    }
}

extension WeakCachedBuilder: LazyInteractable where R: Interactable {
    public var value: Interactable {
        return getOrCreate()
    }
}

extension WeakCachedBuilder: LazyPresentableInteractable where R: PresentableInteractable {
    public var value: PresentableInteractable {
        return getOrCreate()
    }
}

public protocol PresenterProviding {
    associatedtype Presenter: Presentable

    var presenter: Presenter { get }
}

public protocol InteractablePresententerProviding: PresenterProviding, PresentableInteractableConvertible, PresentableInteractableBuildable where Presenter: PresentableInteractable {}

extension InteractablePresententerProviding {
    public var presentableInteractable: PresentableInteractable {
        return presenter
    }

    public func build() -> PresentableInteractable {
        return presentableInteractable
    }
}

public protocol InteractorProviding: InteractableConvertible {
    associatedtype Interactor: Interactable

    var interactor: Interactor { get }
}

extension InteractorProviding {
    public var interactable: Interactable {
        return interactor
    }
}

public protocol PresentableInteractorProviding: InteractorProviding, PresentableInteractableConvertible, PresentableInteractableBuildable where Interactor: PresentableInteractable {}

extension PresentableInteractorProviding {
    public var presentableInteractable: PresentableInteractable {
        return interactor
    }

    public func build() -> PresentableInteractable {
        return presentableInteractable
    }
}

extension AnyBuilder where R == PresentableInteractable {
    public convenience init(presentableInteractable: @escaping @autoclosure () -> PresentableInteractable) {
        self.init { () -> PresentableInteractable in
            return presentableInteractable()
        }
    }

    public convenience init(component: @escaping @autoclosure () -> PresentableInteractableConvertible) {
        self.init { () -> PresentableInteractable in
            return component().presentableInteractable
        }
    }
}
