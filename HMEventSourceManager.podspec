Pod::Spec.new do |s|
    s.platform = :ios
    s.ios.deployment_target = '9.0'
    s.name = "HMEventSourceManager"
    s.summary = "Rx-enabled event source manager for iOS clients."
    s.requires_arc = true
    s.version = "1.0.0"
    s.license = { :type => "Apache-2.0", :file => "LICENSE" }
    s.author = { "Holmusk" => "viethai.pham@holmusk.com" }
    s.homepage = "https://github.com/Holmusk/HMEventSourceManager-iOS.git"
    s.source = { :git => "https://github.com/Holmusk/HMEventSourceManager-iOS.git", :tag => "#{s.version}"}
    s.dependency 'SwiftUtilities/Main'
    s.dependency 'ReachabilitySwift'
    s.dependency 'RxReachability'

    s.subspec 'Main' do |main|
    main.source_files = "HMEventSourceManager/**/*.{swift}"
    end
end
