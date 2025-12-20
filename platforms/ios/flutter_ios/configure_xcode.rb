#!/usr/bin/env ruby
# frozen_string_literal: true

# Xcode 專案最佳化配置腳本
# 用途：
# 1. 配置 NFC 權限、程式碼簽署等設定
# 2. 清理過時的建構檔案
# 3. 優化 Xcode 建置設定
# 4. 修復模擬器程式碼簽署問題

require 'fileutils'

PROJECT_PATH = File.join(__dir__, 'Runner.xcodeproj', 'project.pbxproj')
ENTITLEMENTS_PATH = 'Runner/Runner.entitlements'
FRONTEND_ROOT = File.expand_path('..', __dir__)
BUILD_DIR = File.join(FRONTEND_ROOT, 'build')
DERIVED_DATA = File.expand_path('~/Library/Developer/Xcode/DerivedData')

def log(msg)
  puts "\033[32m✓\033[0m #{msg}"
end

def warn(msg)
  puts "\033[33m⚠\033[0m #{msg}"
end

def error(msg)
  puts "\033[31m✗\033[0m #{msg}"
end

def header(msg)
  puts "\n\033[1;36m#{msg}\033[0m"
end

# =====================================
# 清理功能
# =====================================

def clean_build_artifacts
  header "📁 清理建構目錄..."

  cleaned = 0

  if Dir.exist?(BUILD_DIR)
    ios_build = File.join(BUILD_DIR, 'ios')
    if Dir.exist?(ios_build)
      FileUtils.rm_rf(ios_build)
      cleaned += 1
      log "已清理: #{ios_build}"
    end
  else
    puts "   ℹ️  建構目錄不存在，跳過"
  end

  cleaned
end

def clean_derived_data
  header "🗂️  清理 Xcode DerivedData..."

  cleaned = 0
  runner_derived = Dir.glob(File.join(DERIVED_DATA, 'Runner-*'))

  if runner_derived.empty?
    puts "   ℹ️  無相關 DerivedData 快取"
    return 0
  end

  runner_derived.each do |dir|
    intermediates = File.join(dir, 'Build', 'Intermediates.noindex')
    if Dir.exist?(intermediates)
      stale_files = Dir.glob(File.join(intermediates, '**/*.xcent')) +
                    Dir.glob(File.join(intermediates, '**/*Simulated*.plist'))

      stale_files.each do |file|
        FileUtils.rm_f(file)
        cleaned += 1
      end

      log "已清理 #{stale_files.size} 個過時簽署檔案" if stale_files.any?
    end
  end

  cleaned
end

def clear_extended_attributes
  header "🧹 清除擴展屬性..."

  # 清除專案目錄的擴展屬性
  system("xattr -cr #{__dir__} 2>/dev/null")
  system("dot_clean #{__dir__} 2>/dev/null")

  # 清除 Flutter 快取的擴展屬性
  flutter_cache = `which flutter 2>/dev/null`.strip
  if flutter_cache && !flutter_cache.empty?
    flutter_root = File.dirname(File.dirname(flutter_cache))
    cache_dir = File.join(flutter_root, 'bin', 'cache', 'artifacts', 'engine')
    if Dir.exist?(cache_dir)
      system("xattr -cr #{cache_dir} 2>/dev/null")
      log "已清除 Flutter 引擎快取擴展屬性"
    end
  end

  log "已清除專案擴展屬性"
end

# =====================================
# 專案配置功能
# =====================================

def configure_project
  header "⚙️  配置 Xcode 專案..."

  unless File.exist?(PROJECT_PATH)
    error "找不到專案檔案: #{PROJECT_PATH}"
    return false
  end

  content = File.read(PROJECT_PATH)
  modified = false

  # 1. 添加 CODE_SIGN_ENTITLEMENTS 設定
  unless content.include?('CODE_SIGN_ENTITLEMENTS')
    content.gsub!(/(\s+)(buildSettings = \{[^}]*INFOPLIST_FILE = Runner\/Info\.plist;)/m) do |match|
      indent = $1
      settings = $2
      "#{indent}#{settings}\n#{indent}\t\t\t\tCODE_SIGN_ENTITLEMENTS = \"#{ENTITLEMENTS_PATH}\";"
    end
    modified = true
    log "添加 CODE_SIGN_ENTITLEMENTS 設定"
  end

  # 2. 設定 Development Team
  unless content.include?('DEVELOPMENT_TEAM = ""')
    content.gsub!(/(buildSettings = \{[^}]*)(INFOPLIST_FILE)/m) do |match|
      if match.include?('DEVELOPMENT_TEAM')
        match
      else
        "#{$1}DEVELOPMENT_TEAM = \"\";\n\t\t\t\t#{$2}"
      end
    end
    modified = true
    log "設定 DEVELOPMENT_TEAM"
  end

  # 3. 確保 iOS 最低版本為 13.0
  if content.include?('IPHONEOS_DEPLOYMENT_TARGET = 12')
    content.gsub!('IPHONEOS_DEPLOYMENT_TARGET = 12', 'IPHONEOS_DEPLOYMENT_TARGET = 13')
    modified = true
    log "更新 iOS 最低版本至 13.0"
  end

  # 4. 添加 Runner.entitlements 到專案
  unless content.include?('Runner.entitlements')
    if content =~ /([A-F0-9]{24}) \/\* Info\.plist \*\//
      new_uuid = (0...24).map { ['0'..'9', 'A'..'F'].map(&:to_a).flatten.sample }.join

      content.gsub!(/(\/\* Begin PBXFileReference section \*\/\n)/) do
        "#{$1}\t\t#{new_uuid} /* Runner.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Runner.entitlements; sourceTree = \"<group>\"; };\n"
      end

      if content =~ /(97C146F01CF9000F007C117D \/\* Runner \*\/ = \{[^}]*children = \(\n)/
        content.gsub!($1, "#{$1}\t\t\t\t#{new_uuid} /* Runner.entitlements */,\n")
      end

      modified = true
      log "添加 Runner.entitlements 到專案"
    end
  end

  if modified
    FileUtils.cp(PROJECT_PATH, "#{PROJECT_PATH}.backup")
    File.write(PROJECT_PATH, content)
    log "專案配置完成！已備份至 project.pbxproj.backup"
  else
    log "專案已配置完成，無需修改"
  end

  true
end

# =====================================
# 驗證功能
# =====================================

def verify_podfile
  header "🔍 驗證 Podfile 配置..."

  podfile_path = File.join(__dir__, 'Podfile')

  unless File.exist?(podfile_path)
    warn "找不到 Podfile"
    return
  end

  content = File.read(podfile_path)

  checks = {
    'iOS 13+ 最低版本' => content.include?("platform :ios, '13.0'"),
    '禁用模組驗證器' => content.include?("ENABLE_MODULE_VERIFIER"),
    '模擬器簽署配置' => content.include?("CODE_SIGNING_ALLOWED"),
    'Flutter.h 搜索路徑' => content.include?("HEADER_SEARCH_PATHS"),
    '允許非模組化導入' => content.include?("CLANG_ALLOW_NON_MODULAR_INCLUDES")
  }

  passed = 0
  checks.each do |name, result|
    if result
      log name
      passed += 1
    else
      warn "缺少: #{name}"
    end
  end

  puts "   配置完整度: #{passed}/#{checks.size}"
end

# =====================================
# 主程式
# =====================================

def main
  puts "\n" + "=" * 60
  puts "\033[1;33m🔧 Parliament 1812 - Xcode 專案優化工具\033[0m"
  puts "=" * 60

  # 清理
  cleaned = 0
  cleaned += clean_build_artifacts
  cleaned += clean_derived_data
  clear_extended_attributes

  # 配置
  configure_project

  # 驗證
  verify_podfile

  # 摘要
  puts "\n" + "=" * 60
  puts "\033[1;32m📊 優化完成\033[0m"
  puts "=" * 60
  puts "   清理的檔案數量: #{cleaned}"

  puts "\n\033[1m下一步：\033[0m"
  puts "1. 執行 'flutter clean && flutter pub get'"
  puts "2. 執行 'cd ios && pod install --repo-update'"
  puts "3. 執行 'flutter build ios --simulator --debug'"
  puts "4. 或開啟 Xcode: open ios/Runner.xcworkspace"
  puts "\n" + "=" * 60 + "\n"
end

main if __FILE__ == $PROGRAM_NAME
