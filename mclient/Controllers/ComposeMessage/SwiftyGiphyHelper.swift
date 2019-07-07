//
//  SwiftyGiphyHelper.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

import SwiftyGiphy

@objc protocol SwiftyGiphyHelperDelegate {
    func giphyControllerDidSelectGif(url: URL)
    func giphyControllerDidCancel()
}

@objc class SwiftyGiphyHelper: NSObject, SwiftyGiphyViewControllerDelegate {

    // MARK: - Properties

    private var viewController: SwiftyGiphyViewController?

    @objc public weak var delegate: SwiftyGiphyHelperDelegate?

    // MARK: - Initializers

    @objc public required init(apiKey: String?) {
        SwiftyGiphyAPI.shared.apiKey = apiKey ?? SwiftyGiphyAPI.publicBetaKey
    }

    // MARK: - Public

    @objc public func makeGiphyViewController(theme: MCLTheme) -> UIViewController {
        let giphyVC = SwiftyGiphyViewController()
        giphyVC.delegate = self
        giphyVC.view.backgroundColor = theme.backgroundColor()
        let searchField = giphyVC.searchBar.getSearchField()
        searchField.backgroundColor = theme.searchFieldBackgroundColor()
        searchField.textColor = theme.searchFieldTextColor()
        self.viewController = giphyVC

        return giphyVC
    }

    // MARK: - SwiftyGiphyViewControllerDelegate

    func giphyControllerDidSelectGif(controller: SwiftyGiphyViewController, item: GiphyItem) {
        if let url = URL(string: "https://media.giphy.com/media/\(item.identifier)/giphy.gif") {
            delegate?.giphyControllerDidSelectGif(url: url)
        }
    }

    func giphyControllerDidCancel(controller: SwiftyGiphyViewController) {
        delegate?.giphyControllerDidCancel()
    }
}
