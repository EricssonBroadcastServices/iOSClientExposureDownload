Pod::Spec.new do |spec|
spec.name         = "iOSClientExposureDownload"
spec.version      = "3.2.000"
spec.summary      = "RedBeeMedia iOS SDK ExposureDownload module which combines both Exposure & Download"
spec.homepage     = "https://github.com/EricssonBroadcastServices"
spec.license      = "Apache"
spec.author             = { "EMP" => "jenkinsredbee@gmail.com" }
spec.documentation_url = "README.md"
spec.platforms = { :ios => "11.0" }
spec.source       = { :git => "https://github.com/EricssonBroadcastServices/iOSClientExposureDownload.git", :tag => "v#{spec.version}" }
spec.source_files  = "Sources/iOSClientExposureDownload/**/*.swift"
spec.dependency 'iOSClientExposure', '~>  3.1.1'
spec.dependency 'iOSClientDownload', '~>  3.0.2'
end
