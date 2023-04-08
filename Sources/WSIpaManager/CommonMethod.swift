//
//  CommonMethod.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser
import Foundation

let GET_REQUEST = "GET"
let POST_REQUEST = "POST"

let appstoreDomain = "itunes.apple.com"
let appstoreDomainForLogin = "p71-buy.itunes.apple.com"
let appstoreDomainForDownload = "p25-buy.itunes.apple.com"

let searchApi = "search"
let loginApi = "WebObjects/MZFinance.woa/wa/authenticate"
let downloadApi = "WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct"

let semaphore_search = DispatchSemaphore(value: 0)
let semaphore_login = DispatchSemaphore(value: 0)
let semaphore_loginAuthCode = DispatchSemaphore(value: 0)
let semaphore_download = DispatchSemaphore(value: 0)

let need2authCode = "MZFinance.BadLogin.Configurator_message"
var xmlDic = [String:Any]()

let DYLIB_PATH = "IpaManagerExtraDylib"
let DYLIB_EXECUTABLE_PATH = "@executable_path/\(DYLIB_PATH)/"

let EMPTY_VALUE = "placeholder"

let downloadmanagerPath = "/usr/local/bin/downloadmanager"
let injecttoolPath = "/usr/local/bin/injecttool"
let getheaderPath = "/usr/local/bin/getheader"
let wsipamanagerPath = "/usr/local/bin/WSIpaManager"

/********************* 一些常用路径  **********/
let runtimeTarget1 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libstdc++.6.0.9.dylib"
let runtimeTarget2 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libstdc++.6.dylib"
let runtimeTarget3 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libstdc++.dylib"

let MACTarget1 = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/libstdc++.6.0.9.tbd"
let MACTarget2 = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/libstdc++.6.tbd"
let MACTarget3 = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/libstdc++.tbd"

let iphoneTarget1 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/libstdc++.6.0.9.tbd"
let iphoneTarget2 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/libstdc++.6.tbd"
let iphoneTarget3 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/libstdc++.tbd"

let simulatorTarget1 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/libstdc++.6.0.9.tbd"
let simulatorTarget2 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/libstdc++.6.tbd"
let simulatorTarget3 = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/libstdc++.tbd"
/***************************************************/

class AppInfo {
    var appName:String = ""
    var appBundleID:String = ""
    var appPayloadPath:String = ""
    init() {
    }
}

//公共参数
class CommonMethod: ParsableArguments {
    
    required init() {
    }
    @Option(name: [.short, .long], help: "是否需要日志输出")
    var verbose = false
    
    //    获取UID
    public func guid() -> String {
        
        let MAC_ADDRESS_LENGTH = 6
        
        let bsds: [String] = ["en0", "en1"]
        
        var bsd: String = bsds[0]
        
        var length : size_t = 0
        
        var buffer : [CChar]
        
        var bsdIndex = Int32(if_nametoindex(bsd))
        
        if bsdIndex == 0 {
            
            bsd = bsds[1]
            
            bsdIndex = Int32(if_nametoindex(bsd))
            
            guard bsdIndex != 0 else { fatalError("Could not read MAC address") }
            
        }
        let bsdData = Data(bsd.utf8)
        
        var managementInfoBase = [CTL_NET, AF_ROUTE, 0, AF_LINK, NET_RT_IFLIST, bsdIndex]
        
        guard sysctl(&managementInfoBase, 6, nil, &length, nil, 0) >= 0 else { fatalError("Could not read MAC address") }
        
        buffer = [CChar](unsafeUninitializedCapacity: length, initializingWith: {buffer, initializedCount in
            
            for x in 0..<length { buffer[x] = 0 }
            
            initializedCount = length
            
        })
        guard sysctl(&managementInfoBase, 6, &buffer, &length, nil, 0) >= 0 else { fatalError("Could not read MAC address") }
        
        let infoData = Data(bytes: buffer, count: length)
        
        let indexAfterMsghdr = MemoryLayout<if_msghdr>.stride + 1
        
        let rangeOfToken = infoData[indexAfterMsghdr...].range(of: bsdData)!
        
        let lower = rangeOfToken.upperBound
        
        let upper = lower + MAC_ADDRESS_LENGTH
        
        let macAddressData = infoData[lower..<upper]
        
        let addressBytes = macAddressData.map{ String(format:"%02x", $0) }
        
        return addressBytes.joined().uppercased()
    }
    
    func paraData(data:Data) -> Dictionary<String, Any> {
        let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        if dict == nil {
            showErrorMessage(text: "解析失败")
            return [:]
          }
        return dict as! Dictionary<String, Any>
    }
    
    func needSave(elements:String, needSave:String) -> Void {
        if xmlDic[needSave] as? String == EMPTY_VALUE {
            xmlDic[needSave] = elements
        }
        if elements == needSave {
            xmlDic[needSave] = EMPTY_VALUE
        }
    }
    
    func getXmlDic() -> [String:Any] {
        return xmlDic
    }
    
    func checkEnvConfig() -> Bool {
        
        if FileManager.default.fileExists(atPath: downloadmanagerPath) &&
            FileManager.default.fileExists(atPath: injecttoolPath) &&
            FileManager.default.fileExists(atPath: runtimeTarget1) &&
            FileManager.default.fileExists(atPath: runtimeTarget2) &&
            FileManager.default.fileExists(atPath: runtimeTarget3) &&
            FileManager.default.fileExists(atPath: MACTarget1) &&
            FileManager.default.fileExists(atPath: MACTarget2) &&
            FileManager.default.fileExists(atPath: MACTarget3) &&
            FileManager.default.fileExists(atPath: iphoneTarget1) &&
            FileManager.default.fileExists(atPath: iphoneTarget2) &&
            FileManager.default.fileExists(atPath: iphoneTarget3) &&
            FileManager.default.fileExists(atPath: getheaderPath) &&
            FileManager.default.fileExists(atPath: wsipamanagerPath)
        {
            return true
        }
        return false
    }
    
    //    执行shell脚本
    func runShell(shellPath:String, command: String, needWait:Bool = true, handle:(Int32, String)->()) {
        let task = Process()
        task.launchPath = shellPath
        if shellPath == "/bin/bash" {
            task.arguments = ["-c", command]
        } else {
            task.arguments = command.components(separatedBy: " ")
        }

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        
        if needWait {
            task.waitUntilExit()
        }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8)
        handle(task.terminationStatus, output ?? "")
    }
    
    func isSudo() -> Bool {
        let uid = getuid()
        if uid != 0 {
            return false
        }
        return true
    }
    
    
//    func unzipIpaFile(ipaPath:String) -> AppInfo? {
//        let ipaName = ipaPath.components(separatedBy: "/").last!
//        if ipaName.contains(".ipa") == false {
//            CommonMethod().showErrorMessage(text: "不是ipa文件target = \(ipaPath)")
//            return nil
//        }
//        let ipaNameWithoutExt = ipaName.components(separatedBy: ".").first!
//        let operationPath:String = String(ipaPath.dropLast(ipaName.count))
//        CommonMethod().runShell(shellPath:"/bin/bash", command:"unzip -o \(ipaPath) -d \(operationPath)") { code, des in
//            if code == 0 {
//                do {
//                    let payloadPath = operationPath + ipaNameWithoutExt + "/" + "Payload"
//                    let appRealName = try FileManager.default.contentsOfDirectory(atPath: payloadPath).first!
//                    let appRealNameWithoutExt = appRealName.components(separatedBy: ".").first!
//                    app.appName = appRealNameWithoutExt
//                    app.appPayloadPath = payloadPath
//
//                } catch let err {
//                    CommonMethod().showErrorMessage(text: "解压成功但是文件操作错误\(err)")
//                }
//                
//            } else {
//                CommonMethod().showErrorMessage(text: "解压失败\(des)")
//            }
//        }
//        return app
//    }
    
//    func myBundlePath() -> String {
//////        return ""
////        let bundle = Bundle.module
////        let path = bundle.path(forResource: "downloadmanager", ofType: "")!
////        return path
//        
//        return myBundlePathCustomPath(path: "downloadmanager")
//    }
//    
//    func myBundlePathForInject() -> String {
////        return ""
////        let bundle = Bundle.module
////        let path = bundle.path(forResource: "injecttool", ofType: "")!
////        return path
//        return myBundlePathCustomPath(path: "injecttool")
//
//    }
//    
//    func myBundlePathCustomPath(path:String, extName:String = "") -> String {
//        return ""
////        let bundle = Bundle.module
////        let path = bundle.path(forResource: path, ofType: extName)!
////        return path
//    }
    
    func writeFile(newBinary: Data?, machoPath: String, isRemove:Bool) -> Bool {
        if let b = newBinary {
            do {
                try b.write(to: URL(fileURLWithPath: machoPath))
                return true
            } catch let err {
                if isRemove {
                    CommonMethod().showErrorMessage(text: "反注入成功，写文件失败\(err)")
                } else {
                    CommonMethod().showErrorMessage(text: "注入成功，写文件失败\(err)")
                }
            }
        }
        return false
    }
    
    
    //    展示错误信息
    func showErrorMessage(text:String) -> Void {
        print("❌ \(String(describing: text))")
    }
    
    func showWarningMessage(text:String) -> Void {
        print("⚠️ \(text)")
    }
    
    func showSuccessMessage(text:String) -> Void {
        print("🎉 \(text)")
    }
    
    func showCommonMessage(text:String) -> Void {
        print("👉🏻 \(text)")
    }
    
}

extension Data {
    func extract<T>(_ type: T.Type, offset: Int = 0) -> T {
        let endOffsetSet:Int = offset + MemoryLayout<T>.size
        let data = self[offset..<endOffsetSet]
        return data.withUnsafeBytes { dataBytes in
            dataBytes.baseAddress!.assumingMemoryBound(to: UInt8.self).withMemoryRebound(to: T.self, capacity: 1) { (p) -> T in
                return p.pointee
            }
        }
    }
}

extension String {
    init(_ rawCString: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)) {
        var rawCString = rawCString
        let rawCStringSize = MemoryLayout.size(ofValue: rawCString)
        let string = withUnsafePointer(to: &rawCString) { (pointer) -> String in
            return pointer.withMemoryRebound(to: UInt8.self, capacity: rawCStringSize, {
                return String(cString: $0)
            })
        }
        self.init(string)
    }
    
    init(data: Data, offset: Int, commandSize: Int, loadCommandString: lc_str) {
        let loadCommandStringOffset = Int(loadCommandString.offset)
        let stringOffset = offset + loadCommandStringOffset
        let length = commandSize - loadCommandStringOffset
        self = String(data: data[stringOffset..<(stringOffset + length)], encoding: .utf8)!.trimmingCharacters(in: .controlCharacters)
    }
}

extension FileManager {
    static func open(machoPath: String, backup: Bool, handle: (Data?)->()) {
        do {
            if FileManager.default.fileExists(atPath: machoPath) {
                if backup {
                    let backUpPath = "./\(machoPath.components(separatedBy: "/").last!)_back"
                    if FileManager.default.fileExists(atPath: backUpPath) {
                        try FileManager.default.removeItem(atPath: backUpPath)
                    }
                    try FileManager.default.copyItem(atPath: machoPath, toPath: backUpPath)
                    CommonMethod().showCommonMessage(text: "文件已经备份\(backUpPath)")
                }
                let data = try Data(contentsOf: URL(fileURLWithPath: machoPath))
                handle(data)
            } else {
                CommonMethod().showErrorMessage(text: "mach-o文件不存在")
                print("MachO file not exist !")
                handle(nil)
            }
        } catch let err {
            CommonMethod().showErrorMessage(text: "文件打开错误\(err)")
            handle(nil)
        }
    }
}
