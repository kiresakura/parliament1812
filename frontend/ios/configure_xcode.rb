#!/usr/bin/env ruby
# Xcode 專案自動配置腳本
# 用於配置 NFC 權限、程式碼簽署等設定

require 'fileutils'

PROJECT_PATH = File.join(__dir__, 'Runner.xcodeproj', 'project.pbxproj')
ENTITLEMENTS_PATH = 'Runner/Runner.entitlements'

def log(msg)
  puts "\033[32m✓\033[0m #{msg}"
end

def warn(msg)
  puts "\033[33m⚠\033[0m #{msg}"
end

def error(msg)
  puts "\033[31m✗\033[0m #{msg}"
end

# 讀取 project.pbxproj
content = File.read(PROJECT_PATH)
modified = false

# 1. 添加 CODE_SIGN_ENTITLEMENTS 設定
unless content.include?('CODE_SIGN_ENTITLEMENTS')
  # 找到 Debug 和 Release 的 buildSettings 並添加 entitlements
  content.gsub!(/(\s+)(buildSettings = \{[^}]*INFOPLIST_FILE = Runner\/Info\.plist;)/m) do |match|
    indent = $1
    settings = $2
    "#{indent}#{settings}\n#{indent}\t\t\t\tCODE_SIGN_ENTITLEMENTS = \"#{ENTITLEMENTS_PATH}\";"
  end
  modified = true
  log "添加 CODE_SIGN_ENTITLEMENTS 設定"
end

# 2. 設定 Development Team 為自動（空字串，讓 Xcode 自動管理）
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

# 3. 確保 iOS 最低版本為 13.0（NFC 需要）
if content.include?('IPHONEOS_DEPLOYMENT_TARGET = 12')
  content.gsub!('IPHONEOS_DEPLOYMENT_TARGET = 12', 'IPHONEOS_DEPLOYMENT_TARGET = 13')
  modified = true
  log "更新 iOS 最低版本至 13.0"
end

# 4. 添加 Runner.entitlements 到專案檔案參考
unless content.include?('Runner.entitlements')
  # 找到 Info.plist 的 fileRef 來獲取格式
  if content =~ /([A-F0-9]{24}) \/\* Info\.plist \*\//
    # 生成新的 UUID
    new_uuid = (0...24).map { ['0'..'9', 'A'..'F'].map(&:to_a).flatten.sample }.join

    # 在 PBXFileReference 區段添加 entitlements 檔案
    content.gsub!(/(\/\* Begin PBXFileReference section \*\/\n)/) do
      "#{$1}\t\t#{new_uuid} /* Runner.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Runner.entitlements; sourceTree = \"<group>\"; };\n"
    end

    # 在 Runner group 中添加檔案參考
    if content =~ /(97C146F01CF9000F007C117D \/\* Runner \*\/ = \{[^}]*children = \(\n)/
      content.gsub!($1, "#{$1}\t\t\t\t#{new_uuid} /* Runner.entitlements */,\n")
    end

    modified = true
    log "添加 Runner.entitlements 到專案"
  end
end

if modified
  # 備份原始檔案
  FileUtils.cp(PROJECT_PATH, "#{PROJECT_PATH}.backup")
  File.write(PROJECT_PATH, content)
  log "專案配置完成！已備份原始檔案至 project.pbxproj.backup"
else
  log "專案已經配置完成，無需修改"
end

puts "\n\033[1m下一步：\033[0m"
puts "1. 開啟 Xcode: open Runner.xcworkspace"
puts "2. 選擇你的 iPhone 作為目標裝置"
puts "3. 在 Signing & Capabilities 中選擇你的 Team"
puts "4. 按 ⌘R 運行"
