platform :ios, '9.0'
inhibit_all_warnings!
use_modular_headers!

project 'mclient.xcodeproj'

def mclient_pods
  
  pod 'EDSunriseSet', :git => 'https://github.com/Tricertops/EDSunriseSet'
  pod 'BBBadgeBarButtonItem'
  pod 'MGSwipeTableCell'
  pod 'Valet', '~> 2.4.2'
  pod 'DGActivityIndicatorView'
  pod 'AsyncBlockOperation'
  pod 'ImgurSession', :git => 'https://github.com/Stitch7/ImgurSession'
  pod 'MRProgress', :git => 'https://github.com/Stitch7/MRProgress'
  pod 'HockeySDK'
  pod 'SwiftyGiphy', :modular_headers => true, :git => 'https://github.com/Stitch7/SwiftyGiphy'

#  pod 'InitialsImageView'
#  pod 'MessageKit', :modular_headers => false
#  pod 'MessageInputBar', :modular_headers => false

  pod 'TetrominoTouchKit', :path => "../Tetromino/TetrominoTouchKit"

end

target 'mclient-dev' do
  mclient_pods
end

target 'mclient-alpha' do
  mclient_pods
end

target 'mclient-beta' do
  mclient_pods
end

target 'mclient-store' do
  mclient_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.2'
        end
    end
end
