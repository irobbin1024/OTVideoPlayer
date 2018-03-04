Pod::Spec.new do |s|
    s.name         = 'OTVideoPlayer'
    s.version      = '0.0.1'
    s.summary      = 'a simple and powerful video player base AVPlayer'
    s.homepage     = 'https://github.com/irobbin1024/OTVideoPlayer.git'
    s.license      = 'MIT'
    s.authors      = { 'irobbin1024' => 'irobbin1024@gmail.com' }
    s.platform     = :ios, '6.0'
    s.source       = { :git => 'https://github.com/irobbin1024/OTVideoPlayer.git', :tag => s.version.to_s }
    s.source_files = 'OTVideoPlayer/*.{h,m}'
    s.framework    = 'UIKit'
    s.requires_arc = true
end
