//
//  DispatchQueue+Once.swift
//  HelloMyMap
//
//  Created by gnoocl on 2017/8/10.
//  Copyright © 2017年 gnoocl. All rights reserved.
//

import Foundation
//swift extension: class, enum , protocol,strut
//objc category : class 8
extension DispatchQueue{

    private static var _onceTokens = [String]()
    
  
    public class func once(token:String, job:()->Void){
     
        objc_sync_enter(self)
        

        if _onceTokens.contains(token){
            objc_sync_exit(self)  //用了defer 就不用
            return
        }
            _onceTokens.append(token)
            job()
            objc_sync_exit(self)  //用了defer 就不用
    }
}
