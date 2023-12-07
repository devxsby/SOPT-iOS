//
//  PokeCoordinator.swift
//  PokeFeature
//
//  Created by sejin on 12/7/23.
//  Copyright © 2023 SOPT-iOS. All rights reserved.
//

import UIKit

import Core
import BaseFeatureDependency
import PokeFeatureInterface
import Domain

public
final class PokeCoordinator: DefaultCoordinator {
    public var finishFlow: (() -> Void)?
    
    private let factory: PokeFeatureBuildable
    private let router: Router
    private weak var rootController: UINavigationController?
    
    public init(router: Router, factory: PokeFeatureBuildable) {
        self.router = router
        self.factory = factory
    }
    
    public override func start() {
        showPokeMain()
    }
    
    private func showPokeMain() {
        var pokeMain = factory.makePokeMain()
        
        pokeMain.vm.onNaviBackTap = { [weak self] in
            self?.router.dismissModule(animated: true)
            self?.finishFlow?()
        }
        
        rootController = pokeMain.vc.asNavigationController
        router.present(rootController, animated: true, modalPresentationSytle: .overFullScreen)
    }
}
