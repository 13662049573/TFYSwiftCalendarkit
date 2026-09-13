Pod::Spec.new do |spec|
  spec.name = 'TFYSwiftCalendarkit'
  spec.module_name = 'TFYSwiftCalendarkit'
  spec.version = '1.1.0'
  spec.summary = 'A type-safe, pure Swift calendar view for iOS.'
  spec.description = 'Production-ready month and week calendar UI with custom cells, events, bounded range selection, continuous scrolling, accessibility, UIKit, and SwiftUI support.'
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
