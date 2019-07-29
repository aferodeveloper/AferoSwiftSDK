Pod::Spec.new do |s|

    s.name         = "AferoSwiftSDK"
    s.module_name  = "Afero"
    s.version      = "1.2.3"
    s.summary      = "Library for interacting with Afero devices"

    s.description  = <<-DESC
    Library for interacting with Afero devices.
       DESC

    s.homepage           = "http://developer.afero.io"
    s.license            = { :type => "PROPRIETARY", :file => "LICENSE" }
    s.author             = { "Cora Middleton" => "cora@afero.io" }
    s.social_media_url   = "http://twitter.com/aferodev"
    s.ios.deployment_target = "9.3"
    #s.osx.deployment_target = "10.11"
    s.source       = { :git => "git@github.com:aferodeveloper/AferoSwiftSDK.git", :tag => "#{s.version}" }

    s.default_subspecs = 'Core'

    s.subspec 'Core' do |ss|
        ss.source_files  = "AferoSwiftSDK/Core/**/*"
        ss.dependency 'AferoSofthub', '~> 1.6.3'
        ss.dependency 'CocoaLumberjack/Swift', '~> 3.5'
        ss.dependency 'CryptoSwift'
        ss.dependency 'CocoaZ', '~> 1.4'
        ss.dependency 'ReactiveSwift', '~> 5.0'
        ss.dependency 'PromiseKit/CorePromise', '~> 4.5'
        ss.dependency 'HTTPStatusCodes', '~> 3.2'
        ss.dependency 'RSEnvironment', '0.0.3'
    end
  
    s.subspec 'AFNetworking' do |ss|
        ss.dependency 'AferoSwiftSDK/Core'
        ss.dependency 'AFNetworking', '~> 3.1'
        ss.dependency 'AFOAuth2Manager', '~> 3.0'
        ss.source_files = 'AferoSwiftSDK/AFNetworking/**/*'
    end

end
