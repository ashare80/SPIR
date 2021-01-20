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

import CombineExtensions
import MVVM
import SPIR
import SwiftUI

public protocol RandomWinDependency: Dependency {
    var player1Name: String { get }
    var player2Name: String { get }
    var scoreRelay: ScoreRelay { get }
}

protocol RandomWinBuildable {
    func build(_ dynamicDependency: RandomWin.DynamicDependency) -> Viewable
}

extension AnyDynamicBuilder: RandomWinBuildable where R == Viewable, DynamicDependency == RandomWin.DynamicDependency {}

final class RandomWin: Component<RandomWinDependency>, MVVMComponent {
    var dynamicDependency: DynamicDependency

    public init(parent: Scope, dynamicDependency: DynamicDependency) {
        self.dynamicDependency = dynamicDependency
        super.init(parent: parent)
    }

    var controller: ContentView.Controller {
        weakShared {
            return ContentView.Controller(listener: dynamicDependency.listener,
                                          scoreRelay: dependency.scoreRelay,
                                          player1Name: dependency.player1Name,
                                          player2Name: dependency.player2Name)
        }
    }

    public struct DynamicDependency {
        var listener: RandomWinListener
    }

    struct ContentView: ViewModelView {
        @ObservedObject var model: Controller

        var body: some View {
            VStack {
                Button(action: {
                    self.model.determineWinner()
                }, label: {
                    Text("Magic")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(Color.white)
                })
                    .alert(item: $model.winner) { (winner) -> Alert in
                        Alert(title: Text(model.winnerText), message: nil, dismissButton: .default(Text("That was random..."), action: {
                            self.model.closedAlert(winner: winner)
                        }))
                    }
            }
            .background(Color.white)
            .padding(16)
        }

        final class Controller: ViewLifecycleOwnerController, ViewController {

            var winnerText: String {
                guard let winner = winner else { return "" }
                switch winner {
                case .player1:
                    return "\(player1Name) Won!"
                case .player2:
                    return "\(player2Name) Won!"
                }
            }

            @Published var winner: PlayerType?

            private let listener: RandomWinListener
            private let scoreRelay: ScoreRelay
            private let player1Name: String
            private let player2Name: String

            init(listener: RandomWinListener,
                 scoreRelay: ScoreRelay,
                 player1Name: String,
                 player2Name: String)
            {
                self.listener = listener
                self.scoreRelay = scoreRelay
                self.player1Name = player1Name
                self.player2Name = player2Name
                super.init()
            }

            // MARK: - RandomWinPresentableListener

            func determineWinner() {
                let random = arc4random_uniform(100)
                let winner: PlayerType = random > 50 ? .player1 : .player2
                self.winner = winner
            }

            func closedAlert(winner: PlayerType) {
                scoreRelay.updateScore(with: winner)
                listener.didRandomlyWin()
            }
        }

        #if DEBUG
            struct Preview: PreviewProvider {
                struct RandomWinListenerMock: RandomWinListener {
                    func didRandomlyWin() {}
                }

                static var previews: some View {
                    ContentView(model: Controller(listener: RandomWinListenerMock(),
                                                  scoreRelay: CurrentValueRelay<Score>(),
                                                  player1Name: "player1Name",
                                                  player2Name: "player2Name"))
                }
            }
        #endif
    }
}

public protocol RandomWinListener {
    func didRandomlyWin()
}
