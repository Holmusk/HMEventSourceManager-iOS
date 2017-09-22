# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def allPods
    pod 'SwiftUtilities/Main', :git => 'https://github.com/protoman92/SwiftUtilities.git'
    pod 'ReachabilitySwift'
    pod 'RxReachability'
end

target 'HMEventSourceManager' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  allPods

  # Pods for HMEventSourceManager

  target 'HMEventSourceManagerTests' do
    inherit! :search_paths
    # Pods for testing
    allPods
    pod 'SwiftUtilitiesTests/Main', :git => 'https://github.com/protoman92/SwiftUtilities.git'
  end
  
  target 'HMEventSourceManager-Demo' do
      inherit! :search_paths
      # Pods for testing
      allPods
      pod 'SwiftUIUtilities/Main', :git => 'https://github.com/protoman92/SwiftUIUtilities.git'
  end

end
