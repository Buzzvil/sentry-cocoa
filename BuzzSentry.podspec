Pod::Spec.new do |s|
  s.name         = "BuzzSentry"
  s.version      = "0.0.3"
  s.summary      = "Buzzvil Sentry client for cocoa"
  s.homepage     = "https://github.com/Buzzvil/sentry-cocoa"
  s.license      = "mit"
  s.authors      = "Buzzvil"
  s.source       = { :git => "https://github.com/Buzzvil/sentry-cocoa.git",
                     :tag => s.version.to_s }

  s.ios.deployment_target = "9.0"
  s.module_name  = "BuzzSentry"
  s.requires_arc = true
  s.frameworks = 'Foundation'
  s.libraries = 'z', 'c++'
  s.pod_target_xcconfig = {
      'GCC_ENABLE_CPP_EXCEPTIONS' => 'YES',
      'CLANG_CXX_LANGUAGE_STANDARD' => 'c++14',
      'CLANG_CXX_LIBRARY' => 'libc++'
  }
  s.watchos.pod_target_xcconfig = {
      'OTHER_LDFLAGS' => '$(inherited) -framework WatchKit'
  }

  s.default_subspecs = ['Core']

  s.subspec 'Core' do |sp|
      sp.source_files = "Sources/Sentry/**/*.{h,hpp,m,mm,c,cpp}",
        "Sources/SentryCrash/**/*.{h,hpp,m,mm,c,cpp}"
        
      sp.public_header_files =
        "Sources/Sentry/Public/*.h"
      
  end
end
