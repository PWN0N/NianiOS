//
//  ModelViewController.swift
//  Nian iOS
//
//  Created by WebosterBob on 10/23/15.
//  Copyright © 2015 Sa. All rights reserved.
//

import UIKit


class PatternViewController: AccountBaseViewController {
    
    /// "模式"选中时的颜色
    let c5Color = UIColor(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0, alpha: 1.0)
    /// "模式"未选中时的颜色
    let c7Color = UIColor(red: 0xB3/255.0, green: 0xB3/255.0, blue: 0xB3/255.0, alpha: 1.0)
    
    /// 中间分割线的宽度
    @IBOutlet weak var widthLine: NSLayoutConstraint!
    /// 困难模式的图片
    @IBOutlet weak var toughImageView: UIImageView!
    /// 简单模式的图片
    @IBOutlet weak var simpleImageView: UIImageView!
    /// "困难" label
    @IBOutlet weak var toughLabel: UILabel!
    /// "简单" label
    @IBOutlet weak var simpleLabel: UILabel!
    /// "困难模式"描述 label
    @IBOutlet weak var toughIllustrate: UILabel!
    /// "简单模式"描述 label
    @IBOutlet weak var simpleIllustate: UILabel!
    ///
    @IBOutlet weak var toughView: UIView!
    ///
    @IBOutlet weak var simpleView: UIView!
    ///
    @IBOutlet weak var containerView: UIView!
    /// 中间的分割线
    @IBOutlet weak var viewLine: UIView!
    ///
    @IBOutlet weak var accompolishButton: CustomButton!
    
    /// 注册时应提供的信息
    var regInfo: RegInfo?
    /// 玩念的模式 -- 困难 or 简单
    var playMode: PlayMode?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.playMode = .easy
        setPlayMode(PlayMode.easy)
    }

    /**
    设置玩念的模式
    */
    func setPlayMode(mode: PlayMode) {
        if mode == PlayMode.easy {
            self.simpleLabel.textColor = c5Color
            self.simpleIllustate.textColor = c5Color
            
            self.toughLabel.textColor = c7Color
            self.toughIllustrate.textColor = c7Color
            
            self.playMode = PlayMode.easy
        } else {
            self.simpleLabel.textColor = c7Color
            self.simpleIllustate.textColor = c7Color
            
            self.toughLabel.textColor = c5Color
            self.toughIllustrate.textColor = c5Color
            
            self.playMode = PlayMode.hard
        }
    }
    
    /**
    tap 手势 on tough mode view
    */
    @IBAction func touchOnLeftView(sender: UITapGestureRecognizer) {
        setPlayMode(PlayMode.hard)
    }
    
    /**
    tap 手势 on simple mode view
    */
    @IBAction func touchOnRightView(sender: UITapGestureRecognizer) {
        setPlayMode(PlayMode.easy)
    }
    
    /**
    点击“完成” Button, 完成注册
    */
    @IBAction func accompolishRegister(sender: UIButton) {
        self.accompolishButton.startAnimating()
        
        let _password = "n*A\(self.regInfo!.password!)"
        
        LogOrRegModel.register(email: self.regInfo!.email!,
            password: _password.md5,
            username: self.regInfo!.nickname!,
            daily: self.playMode!.rawValue) {
               (task, responseObject, error) in
                
                self.accompolishButton.stopAnimating()
                self.accompolishButton.setTitle("完成", forState: .Normal)
                
                if let _ = error { // 服务器返回错误
                    self.view.showTipText("网络有点问题，等一会儿再试")
                } else {
                    let json = JSON(responseObject!)
                    
                    if json["error"] == 2 { // 服务器返回的数据包含“错误信息”
                        self.view.showTipText("用户名被占用...", delay: 2)
                        self.dismissViewControllerAnimated(true, completion: nil)
                        
                    } else if json["error"] == 0 { // 服务器返回正常，注册成功
                        NSUserDefaults.standardUserDefaults().setObject(self.regInfo!.nickname!, forKey: "user")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                        // 注册后一天提供推送，形成第一天习惯
                        thepush("Mua!", dateSinceNow: 60 * 60 * 24, willReapt: false, id: "signup")
                      
                        self.presentViewController(self.enterHome(json), animated: true, completion: nil)
                        
                        globalWillReEnter = 0  // ????? <-  这是什么鬼参数
                    }
                    
                }
                
        }
        
    }
}