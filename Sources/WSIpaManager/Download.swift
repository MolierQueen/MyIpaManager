//
//  Download.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser
import Foundation
class Download: NSObject, ParsableCommand, XMLParserDelegate {
    required override init() {
    }
    static var configuration = CommandConfiguration(abstract: "从AppleStore下载App")
    
    @OptionGroup
    var commonParas: CommonMethod
    
    @Option(name: [.short, .customLong("trackid")], help: "输入app在applestore上的id")
    var trackID: String = "414478124"
    
    @Option(name: [.short, .customLong("bundle")], help: "输入app在applestore上的bundleID")
    //    var bundle: String = "com.tencent.xin"
    var bundle: String = "com.tencent.xin"
    
    
    func run() {
        Configenv().run()
        getDownloadUrl()
        downloadipaWith(urlStr: "download","-b", self.bundle)
    }
    
    func getDownloadUrl() -> Void {
        var urlStr = "https://"+appstoreDomainForDownload+"/"+downloadApi+"?"+"guid=\(String(describing: CommonMethod().guid()))"
        urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let finaURL = URL(string: urlStr)
        print("开始获取下载链接 url == \(urlStr)")
        var paraDic = [String:String]()
        paraDic["creditDisplay"] = ""
        paraDic["guid"] = CommonMethod().guid()
        paraDic["salableAdamId"] = trackID
        
        var paraData:Data = Data()
        do {
            paraData = try JSONSerialization.data(withJSONObject: paraDic)
        } catch {
            print(error)
        }
        
        let session: URLSession = URLSession.shared
        var request: URLRequest = URLRequest(url: finaURL!)
        request.httpMethod = "POST"
        request.httpBody = paraData
        
        request.setValue("Configurator/2.0 (Macintosh; OS X 10.12.6; 16G29) AppleWebKit/2603.3.8", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        guard let dsid = UserDefaults.standard.string(forKey: "dsid") else { CommonMethod().showErrorMessage(text: "还没授权")
            return
        }
        request.setValue(dsid, forHTTPHeaderField: "X-Dsid")
        request.setValue(dsid, forHTTPHeaderField: "iCloud-DSID")
        let semaphore_MyDown = DispatchSemaphore(value: 0)
        
        let task = session.dataTask(with: request as URLRequest) { data, rsp, err in
            if err != nil {
                CommonMethod().showErrorMessage(text: "请求失败\(String(describing: err))")
            } else {
                
//                let string:String! = String.init(data: data!, encoding: .utf8)
                let parser = XMLParser(data: data!)
                //设置delegate
                parser.delegate = self
                //开始解析
                parser.parse()
                //                print("++我的解析字典==\(CommonMethod().getXmlDic())")
                let url = CommonMethod().getXmlDic()["URL"] ?? EMPTY_VALUE
                if url as! String == EMPTY_VALUE {
                    CommonMethod().showErrorMessage(text: "下载失败 没有获取到下载链接")
                } else {
                    UserDefaults.standard.set(url, forKey: "downloadurl")
                    UserDefaults.standard.synchronize()
                    CommonMethod().showSuccessMessage(text: "获取下载链接为：\(url) 准备开始下载")
                }
                //                CommonMethod().showSuccessMessage(text: "请求成功 ✅元数据----  \(String(describing: string))")
            }
            
            semaphore_MyDown.signal()
        }
        task.resume()
        semaphore_MyDown.wait()
    }
    
    // 遇到字符串时调用
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        CommonMethod().needSave(elements: data, needSave: "URL")
        CommonMethod().needSave(elements: data, needSave: "sinf")
        CommonMethod().needSave(elements: data, needSave: "metadata")
        CommonMethod().needSave(elements: data, needSave: "bundleShortVersionString")
        CommonMethod().needSave(elements: data, needSave: "artistName")
    }
    
    
    func downloadipaWith(urlStr:String...) -> Void {
        
        //                for i in 0..<10 {
        //                    Thread.sleep(forTimeInterval: 1)
        //                    let x = 0
        //                    let y = 1
        //                    //            打印进度
        //                    print( "\u{1B}[1A\u{1B}[KDownloaded:我是\(i) ")
        //                    fflush(__stdoutp)
        //                }
        //        shell
        //        ["-c", "curl -# -O https://example.com/large_file.zip"]
//        print("download -b \(bundle)")

//        CommonMethod().runShell(shellPath:CommonMethod().myBundlePath(), command: "download -b \(bundle)") { code, desc in
//            print("+++\(desc)")
//            return
//        }
        let task = Process()
        task.launchPath = "/usr/local/bin/downloadmanager"
        task.arguments = urlStr
        task.launch()
        task.waitUntilExit()
        return
    }
    
    
    
    
   
    
}
