# Uncomment the next line to define a global platform for your project
platform :ios, '11.4'

target 'nanozap' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for nanozap
  pod 'SwiftProtobuf' , '~> 1.0'
  pod 'SwiftGRPC', :inhibit_warnings => true
  pod 'Valet'
  pod 'SwiftLint'
  pod 'PasswordExtension'
  pod 'QRCodeReader.swift', '~> 8.2.0'
  pod 'RxSwift',    '~> 4.0'
  pod 'RxCocoa',    '~> 4.0'

  target 'nanozapTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'nanozapUITests' do
    inherit! :search_paths
    # Pods for testing
  end
end
