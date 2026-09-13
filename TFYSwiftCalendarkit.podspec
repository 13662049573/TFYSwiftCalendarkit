Pod::Spec.new do |spec|
  spec.name = 'TFYSwiftCalendarkit'
  spec.module_name = 'TFYSwiftCalendarkit'
  spec.version = '1.1.0'
  spec.summary = '一个类型安全、纯 Swift 实现的 iOS 日历组件。'
  spec.description = '面向生产环境的月视图与周视图日历组件，支持自定义单元格、事件标记、范围选择、连续滚动、无障碍访问，以及 UIKit 和 SwiftUI。'
  spec.homepage = 'https://github.com/13662049573/TFYSwiftCalendarkit'
  spec.documentation_url = 'https://github.com/13662049573/TFYSwiftCalendarkit#readme'
  spec.license = { :type => 'MIT', :file => 'LICENSE' }
  spec.author = { 'Tianfeng You' => '420144542@qq.com' }
  spec.source = { :git => 'https://github.com/13662049573/TFYSwiftCalendarkit.git', :tag => spec.version.to_s }

  spec.ios.deployment_target = '15.0'
  spec.swift_version = '6.0'
  spec.requires_arc = true

  spec.source_files = 'Sources/TFYSwiftCalendarkit/**/*.swift'
  spec.resource_bundles = {
    'TFYSwiftCalendarkit_Resources' => [
      'Sources/TFYSwiftCalendarkit/PrivacyInfo.xcprivacy',
      'Sources/TFYSwiftCalendarkit/Resources/**/*'
    ]
  }
  spec.frameworks = 'Foundation', 'UIKit', 'SwiftUI'

  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/TFYSwiftCalendarkitTests/**/*.swift'
  end
end
