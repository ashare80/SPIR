//
//  Copyright (c) 2021. Adam Share
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

import Combine
import Foundation

public typealias CurrentValueRelay<Output> = CurrentValueSubject<Output, Never>
public typealias PassthroughRelay<Output> = PassthroughSubject<Output, Never>
public typealias RelayPublisher<Output> = AnyPublisher<Output, Never>
public typealias ReplayRelay<Output> = ReplaySubject<Output, Never>

public extension Publisher where Failure == Never {
    /// Maps a `Never` to the new `F` failure type.
    func mapError<F>() -> Publishers.MapError<Self, F> {
        mapError { _ -> F in }
    }
}
