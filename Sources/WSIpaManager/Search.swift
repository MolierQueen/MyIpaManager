//
//  Search.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser
import Foundation
class Search: ParsableCommand {
    required init() {
    }
    
    static var configuration = CommandConfiguration(abstract: "搜索appstore上的App")

    //    这是一个参数列表
    @OptionGroup
    var options: CommonMethod
    
    @Option(name: [.short, .customLong("trackid")], help: "输入app在applestore上的id")
    var trackID: String = ""
    
    @Option(name: [.short, .customLong("country")], help: "输入app在applestore上的国家")
    var country: String = "CN"
    
    @Option(name: [.short], help: "输入app的名字")
    var name: String = "微信"
    
    @Option(name: [.short], help: "结果条数限制")
    var limit: String = "1"


     func run() {
         
//         print("请输入字符串：")
//         let valueOne = readLine();
//         print("aaaa\(String(describing: valueOne))")
         searchAppRequest()
    }
    
    func searchAppRequest() -> Void {
        var urlStr = "https://"+appstoreDomain+"/"+searchApi+"?"+"media=media&entity=software"+"&country="+country+"&limit="+limit+"&term="+name
        urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let finaURL = URL(string: urlStr)
//        print("开始搜索 url == \(urlStr)")
        print("开始在Appstore上搜索\(name)...")

        self.request(url: finaURL!)
    }
    
    
    //    请求搜索接口
    func request(url:URL)   {
        
        let session: URLSession = URLSession.shared
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = GET_REQUEST
        let task = session.dataTask(with: request) { resultData, rsp, error in
            if (error != nil) {
                CommonMethod().showErrorMessage(text: "请求出错 \(String(describing: error))")
            } else {
                let dict = CommonMethod().paraData(data: resultData!)
                let resultArr : Array = dict["results"] as? Array<Any> ?? []
                if resultArr.count == 1 {
                    let finalResult : Dictionary = resultArr.first as! Dictionary<String, Any>
                    let bundleID = finalResult["bundleId"] ?? ""
                    let trackID = finalResult["trackId"] ?? ""
                    let version = finalResult["version"] ?? ""
                    let appstoreURL = finalResult["trackViewUrl"] ?? ""
                    CommonMethod().showSuccessMessage(text: "搜索完成")
                    print("bundle = \(bundleID)")
                    print("trackID = \(trackID)")
                    print("版本号 = \(version)")
                    print("商店链接 = \(appstoreURL)")
                } else {
                    CommonMethod().showErrorMessage(text: "未找到相关产品")
                }
            }
            semaphore_search.signal()
        }
        task.resume()
        semaphore_search.wait()
    }

}
