# Uncomment the next line to define a global platform for your project
platform :ios, '17.6'

# Minimum deployment target applied to every pod target. Xcode 27 refuses to build
# targets below iOS 15, and several pods still declare 8.0-13.0 in their podspecs.
MIN_IOS_DEPLOYMENT_TARGET = '17.6'

target 'SDCrew' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

    pod 'OAuthSwift', :git => 'https://github.com/OAuthSwift/OAuthSwift.git'
    pod 'DLRadioButton', '~> 1.4'
    pod 'SwiftyJSON', '~> 4.0'
    pod 'SAMKeychain'
    pod 'AppCenter'
  # Pods for SDCrew

  target 'SDCrewTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'SDCrewUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = MIN_IOS_DEPLOYMENT_TARGET
    end
  end
end
