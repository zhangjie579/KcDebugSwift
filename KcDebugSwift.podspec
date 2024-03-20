#
# Be sure to run `pod lib lint KcDebugSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KcDebugSwift'
  s.version          = '0.1.3'
  s.summary          = 'A short description of KcDebugSwift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/zhangjie579'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '张杰' => '527512749@qq.com' }
  s.source           = { :git => 'https://github.com/zhangjie579/KcDebugSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  # swifty版本号
  s.swift_version = "5.0"

#  s.source_files = 'KcDebugSwift/Classes/**/*'
  
  # s.resource_bundles = {
  #   'KcDebugSwift' => ['KcDebugSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  # lldb调试成员变量ivar
  s.subspec 'FindProperty' do |d|
      d.source_files = 'KcDebugSwift/Classes/FindProperty/**/*'
      d.dependency "KcDebugSwift/Tool"
      d.frameworks = 'UIKit'
  end
  
  # 查找循环引用
#  s.subspec 'CircularReference' do |ss|
#      ss.source_files = 'KcDebugSwift/Classes/CircularReference/**/*'
#      ss.dependency "KcDebugSwift/FindProperty"
#      ss.dependency "KcDebugSwift/Tool"
#      ss.dependency "KcDebugSwift/Associations"
#      ss.frameworks = 'UIKit'
#  end
  
  s.subspec 'Tool' do |d|
      d.source_files = 'KcDebugSwift/Classes/Tool/**/*'
      d.frameworks = 'UIKit'
      d.dependency "KcDebugSwift/MRC"
  end
  
  # hook关联对象
#  s.subspec 'Associations' do |ss|
#      ss.source_files = 'KcDebugSwift/Classes/Associations/**/*'
#      ss.dependency "fishhook"
#      ss.requires_arc = false # 需要mrc
#  end
  
  # UI属性
  s.subspec 'UIProperty' do |ss|
      ss.source_files = 'KcDebugSwift/Classes/UIProperty/**/*'
      ss.dependency "KcDebugSwift/FindProperty"
      ss.frameworks = 'UIKit'
  end
  
  s.subspec 'MRC' do |ss|
      ss.requires_arc = false # 默认为MRC
      ss.source_files = 'KcDebugSwift/Classes/MRC/**/*'
  end
  
end
