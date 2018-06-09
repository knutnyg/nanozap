# Uncomment the next line to define a global platform for your project
platform :ios, '11.4'

target 'nanozap' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for nanozap
  pod 'SwiftProtobuf' , '~> 1.0'
  pod 'SwiftGRPC', :inhibit_warnings => true
  pod 'SwiftLint'

  target 'nanozapTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'nanozapUITests' do
    inherit! :search_paths
    # Pods for testing
  end
end
