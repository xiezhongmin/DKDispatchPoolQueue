#
# Be sure to run `pod lib lint DKDispatchPoolQueue.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DKDispatchPoolQueue'
  s.version          = '0.1.0'
  s.summary          = 'The serial queue from manage global dispath queue pool.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/git/DKDispatchPoolQueue'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'git' => '364101515@qq.com' }
  s.source           = { :git => 'https://github.com/git/DKDispatchPoolQueue.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'DKDispatchPoolQueue/*.{h,m}'
  s.public_header_files = 'DKDispatchPoolQueue/*.{h}'
  s.frameworks = 'UIKit'
  
end
