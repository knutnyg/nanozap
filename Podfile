# Uncomment the next line to define a global platform for your project
platform :ios, '11.4'

target 'blixzt' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for blixzt
  pod 'SwiftProtobuf', '~> 1.0'
  pod 'SwiftGRPC', :inhibit_warnings => true
  pod 'Valet'
  pod 'SwiftLint'
  pod 'PasswordExtension'
  pod 'QRCodeReader.swift', '~> 8.2.0'
  pod 'RxSwift', '~> 4.0'
  pod 'RxCocoa', '~> 4.0'
  pod 'Result', '~> 4.0.0'
  pod 'FontAwesome.swift'
  pod 'SwiftMessages'
  pod 'SwiftyJSON', '~> 4.0'
  pod 'SnapKit', '~> 4.0'
  pod "QRCode", :git => "https://github.com/ekscrypto/QRCode.git"

  target 'blixztTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'blixztUITests' do
    inherit! :search_paths
    # Pods for testing
  end
end
