//
//  UserAvatarImageView.swift
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

typealias User = MCLUser
class UserAvatarImageView: UIImageView {

    var user: User? {
        didSet {
            guard let user = self.user else { return }
            setInitials(user: user)
            loadAvatar(user: user)
        }
    }

    @objc init(frame: CGRect, user: User) {
        self.user = user
        super.init(frame: frame)

        setInitials(user: user)
        loadAvatar(user: user)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setInitials(user: User) {
        var fontSize = self.frame.width / 2.7
        fontSize.round()
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                          NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.medium)]
        setImageForName(user.username, backgroundColor: .darkGray, circular: true, textAttributes: attributes)
        layer.cornerRadius = 0
        layer.masksToBounds = false
//        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
    }

    func loadAvatar(user: User) {
        guard let username = user.username else { return }

        let urlString = "\(kMServiceBaseURL)/user/\(username)/avatar.jpg"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                print("Failed fetching image \(urlString): \(error.debugDescription)")
                return
            }

            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Not a proper HTTPURLResponse or statusCode")
                return
            }

            DispatchQueue.main.async {
                guard let image = UIImage(data: data!) else { return }

                self.image = image
                self.contentMode = .scaleAspectFill
                self.layer.cornerRadius = self.frame.size.height / 2
                self.layer.masksToBounds = true
//                self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
//                self.setNeedsLayout()
//                self.layoutIfNeeded()
            }
        }.resume()
    }
}
