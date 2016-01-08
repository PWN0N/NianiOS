//
//  AddReddit + Function.swift
//  Nian iOS
//
//  Created by Sa on 15/9/6.
//  Copyright © 2015年 Sa. All rights reserved.
//

import Foundation
import SpriteKit
import AssetsLibrary

extension AddStep {
    func onImage() {
        field2.resignFirstResponder()
        LSYAlbum.sharedAlbum().setupAlbumGroups { (groups) -> () in
            let albumPicker = LSYAlbumPicker()
            albumPicker.group = groups[0] as! ALAssetsGroup
            albumPicker.maxminumNumber = 9 - self.imageArray.count
            albumPicker.delegate = self
            self.navigationController?.pushViewController(albumPicker, animated: true)
        }
    }
    
    /* 上传队列完成后，准备提交到服务器 */
    func upYunMulti(data: NSDictionary?, count: Int) {
        go {
            if data != nil {
                self.uploadArray.addObject(data!)
            } else {
                let n = self.hasUploadedArray[count]
                let images = self.dataEdit!.objectForKey("images") as! NSArray
                let image = images[n] as! NSDictionary
                self.uploadArray.addObject(image)
            }
            let num = count + 1
            /* 按照队列进行上传 */
            if self.imageArray.count > num {
                let op = UpyunOperation()
                op.num = num
                op.hasUploaded = self.hasUploadedArray[num] >= 0
                op.image = self.imageArray[num]
                op.delegate = self
                self.queue.addOperation(op)
            } else {
                /* 全部上传成功后，提交服务器 */
                self.addStep()
            }
        }
    }
    
    /* 提交服务器 */
    func addStep() {
        var type: Int = 5
        if field2.text == "" {
            if imageArray.count == 0 {
                /* 无文字，无图片，签到 */
                type = 1
            } else if imageArray.count == 1 {
                /* 无文字，单图片 */
                type = 6
            } else {
                /* 无文字，多图片 */
                type = 4
            }
        } else {
            if imageArray.count == 0 {
                /* 有文字，无图片 */
                type = 7
            } else if imageArray.count == 1 {
                /* 有文字，单图片 */
                type = 5
            } else {
                /* 有文字，多图片 */
                type = 3
            }
        }
        
        /* 不管编辑或新增，都把当前的记本 id 加入缓存 */
        Cookies.set(idDream, forKey: "DreamNewest")
        
        if willEdit {
            let sid = dataEdit!.stringAttributeForKey("sid")
            AddStepModel.postEditStep(content: field2.text, stepType: type, images: uploadArray, sid: sid, callback: { (task, data, error) -> Void in
                if let d = data as? NSDictionary {
                    let error = d.stringAttributeForKey("error")
                    if error == "0" {
                        let mutableData = NSMutableDictionary(dictionary: self.dataEdit!)
                        mutableData.setValue(self.field2.text, forKey: "content")
                        mutableData.setValue(self.uploadArray, forKey: "images")
                        mutableData.setValue(type, forKey: "type")
                        if self.uploadArray.count > 0 {
                            if let image = self.uploadArray[0] as? NSDictionary {
                                mutableData.setValue(image.stringAttributeForKey("path"), forKey: "image")
                                mutableData.setValue(image.stringAttributeForKey("width"), forKey: "width")
                                mutableData.setValue(image.stringAttributeForKey("height"), forKey: "height")
                            }
                        } else {
                            mutableData.setValue("", forKey: "image")
                            mutableData.setValue("0", forKey: "width")
                            mutableData.setValue("0", forKey: "height")
                        }
                        
                        let heightContent = (self.field2.text as NSString).sizeWithConstrainedToWidth(globalWidth - 40, fromFont: UIFont.systemFontOfSize(16), lineSpace: 5).height
                        var heightCell: CGFloat = 0
                        var heightImage: CGFloat = 0
                        
                        if type == 7 {
                            /* 无图，有文字 */
                            heightCell = heightContent + SIZE_PADDING * 4 + SIZE_IMAGEHEAD_WIDTH + SIZE_LABEL_HEIGHT
                        } else if type == 1 {
                            /* 无图，无文字 */
                            heightCell = 155 + 23
                        } else {
                            /* 多图带文字 */
                            if type == 3 {
                                let count = ceil(CGFloat(self.uploadArray.count) / 3)
                                let h = (globalWidth - SIZE_PADDING * 2 - SIZE_COLLECTION_PADDING * 2) / 3 + SIZE_COLLECTION_PADDING
                                heightImage = h * count - SIZE_COLLECTION_PADDING
                                heightCell = heightContent + heightImage + SIZE_PADDING * 5 + SIZE_IMAGEHEAD_WIDTH + SIZE_LABEL_HEIGHT
                            } else if type == 4 {
                                /* 多图不带文字 */
                                let count = ceil(CGFloat(self.uploadArray.count) / 3)
                                let h = (globalWidth - SIZE_PADDING * 2 - SIZE_COLLECTION_PADDING * 2) / 3 + SIZE_COLLECTION_PADDING
                                heightImage = h * count - SIZE_COLLECTION_PADDING
                                heightCell = heightImage + SIZE_PADDING * 4 + SIZE_IMAGEHEAD_WIDTH + SIZE_LABEL_HEIGHT
                            } else {
                                /* 单图 */
                                if let image = self.uploadArray[0] as? NSDictionary {
                                    let w = (image.stringAttributeForKey("width") as NSString).floatValue
                                    let h = (image.stringAttributeForKey("height") as NSString).floatValue
                                    heightImage = CGFloat(h * Float(globalWidth - 40) / w)
                                    if type == 6 {
                                        /* 有文字，单图片 */
                                        heightCell = heightImage + SIZE_PADDING * 4 + SIZE_IMAGEHEAD_WIDTH + SIZE_LABEL_HEIGHT
                                    } else if type == 5 {
                                        /* 无文字，单图片 */
                                        heightCell = heightContent + heightImage + SIZE_PADDING * 5 + SIZE_IMAGEHEAD_WIDTH + SIZE_LABEL_HEIGHT
                                    }
                                }
                            }
                        }
                        mutableData["heightImage"] = heightImage
                        mutableData["heightCell"] = heightCell
                        mutableData["heightContent"] = heightContent
                        
                        self.delegate?.editStepRow = self.rowEdit
                        self.delegate?.editStepData = mutableData
                        self.delegate?.Editstep()
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }
            })
        } else {
            AddStepModel.postAddStep(content: field2.text, stepType: type, images: uploadArray, dreamId: idDream, callback: { (task, data, error) -> Void in
                if let d = data as? NSDictionary {
                    let error = d.stringAttributeForKey("error")
                    if error == "0" {
                        let result = d.objectForKey("data") as! NSDictionary
                        let coin = result.stringAttributeForKey("coin")
                        let totalCoin = result.stringAttributeForKey("totalCoin")
                        let isfirst = result.stringAttributeForKey("isfirst")
                        self.field2.resignFirstResponder()
                        
                        go {
                            /* 清除草稿 */
                            print("清除草稿")
                            Cookies.remove("draft")
                            let a = NSUserDefaults.standardUserDefaults()
                            print(a)
                            
                            /* 创建进展卡片 */
                            let modeCard = SACookie("modeCard")
                            if modeCard == "off" {
                            } else {
                                let card = (NSBundle.mainBundle().loadNibNamed("Card", owner: self, options: nil) as NSArray).objectAtIndex(0) as! Card
                                card.content = self.field2.text
                                if self.uploadArray.count > 0 {
                                    let image = self.uploadArray[0] as! NSDictionary
                                    card.widthImage = image.stringAttributeForKey("width")
                                    card.heightImage = image.stringAttributeForKey("height")
                                    card.url = "http://img.nian.so/step/\(image.stringAttributeForKey("path"))!large"
                                }
                                card.onCardSave()
                            }
                        }
                        
                        if isfirst == "1" {
                            Nian.saegg(coin, totalCoin: totalCoin)
                        }
                        let vc = DreamViewController()
                        vc.Id = self.idDream
                        vc.willBackToRootViewController = true
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        self.showTipText("服务器坏了")
                    }
                } else {
                    self.showTipText("服务器坏了")
                }
            })
        }
    }
    
    /* 点击提交进展按钮 */
    func add() {
        self.setBarButtonLoading()
        go {
            if self.imageArray.count > 0 {
                self.queue.maxConcurrentOperationCount = 1
                if self.imageArray.count > 0 {
                    let op = UpyunOperation()
                    op.num = 0
                    /* 编辑图片为正，上传图片为负，如果大于等于零，就已上传 */
                    op.hasUploaded = self.hasUploadedArray[0] >= 0
                    op.image = self.imageArray[0]
                    op.delegate = self
                    self.queue.addOperation(op)
                }
            } else {
                self.addStep()
            }
        }
    }
    
    /* 筛选多图完成后调用 */
    func AlbumPickerDidFinishPick(assets:NSArray) {
        for asset in assets {
            if let a = asset as? ALAsset {
                if  a.valueForProperty("ALAssetPropertyType").isEqual("ALAssetTypePhoto") {
                    imageArray.append(a)
                    hasUploadedArray.append(-1)
                }
            }
        }
        reLayout()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func onViewDream() {
        if tableView.hidden {
            var hTableView = globalHeight - 64 - self.viewDream.height() - viewHolder.height() - keyboardHeight
            hTableView = max(hTableView, 0)
            tableView.setHeight(hTableView)
            tableView.hidden = false
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.imageArrow.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
            })
        } else {
            tableView.hidden = true
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.imageArrow.transform = CGAffineTransformMakeRotation(0)
            })
        }
    }
    
    func reLayout() {
        collectionView.reloadData()
        let num = ceil(CGFloat(imageArray.count) / 3)
        var h = (globalWidth - size_field_padding * 2 - size_collectionview_padding * 2) / 3 + size_collectionview_padding
        h = num * h
        collectionView.setHeight(h)
        field2.setY(collectionView.bottom())
        labelPlaceholder.frame.origin = CGPointMake(field2.x() + 6, field2.y() + 6)
        setScrollContentHeight()
    }
}


extension NIAlert {
    func evolution(url: String) {
        //        var _tmpImg = self.imgView?.image!
        
        UIView.animateWithDuration(0.7, animations: {
            self.imgView!.setScale(0.8)
            }, completion: { (Bool) -> Void in
                UIView.animateWithDuration(0.15, animations: {
                    self.imgView!.setScale(0.75)
                    }, completion: { (Bool) -> Void in
                        UIView.animateWithDuration(0.15, animations: {
                            self.imgView!.setScale(0.8)
                            }, completion: { (Bool) -> Void in
                                UIView.animateWithDuration(0.15, animations: {
                                    self.imgView!.setScale(0.75)
                                    }, completion: { (Bool) -> Void in
                                        UIView.animateWithDuration(0.15, animations: {
                                            self.imgView!.setScale(0.8)
                                            }, completion: { (Bool) -> Void in
                                                UIView.animateWithDuration(0.15, animations: {
                                                    self.imgView!.setScale(0.75)
                                                    }, completion: { (Bool) -> Void in
                                                        UIView.animateWithDuration(0.2, animations: {
                                                            self.imgView!.setScale(1.15)
                                                            }, completion: { (Bool) -> Void in
                                                                self.imgView?.image = nil
                                                                if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
                                                                    let skView = SKView(frame: CGRectMake(0, 0, 272, 108))
                                                                    if #available(iOS 8.0, *) {
                                                                        skView.allowsTransparency = true
                                                                    }
                                                                    self._containerView!.addSubview(skView)
                                                                    scene.scaleMode = SKSceneScaleMode.AspectFit
                                                                    skView.presentScene(scene)
                                                                    scene.setupViews()
                                                                    self._containerView?.sendSubviewToBack(skView)
                                                                }
                                                                delay(0.1, closure: {
                                                                    self.imgView!.setScale(1.35)
                                                                    self.imgView?.alpha = 0
                                                                    self.imgView?.setPet("http://img.nian.so/pets/\(url)!d")
                                                                    UIView.animateWithDuration(0.1, animations: {
                                                                        self.imgView?.alpha = 1
                                                                        self.imgView!.setScale(1.55)
                                                                        }, completion: { (Bool) -> Void in
                                                                            UIView.animateWithDuration(0.2, animations: { () -> Void in
                                                                                self.imgView!.setScale(1.2)
                                                                            })
                                                                            UIView.animateWithDuration(1, delay: 1, options: UIViewAnimationOptions(), animations: {
                                                                                self.imgView!.setScale(1)
                                                                                }, completion: { (Bool) -> Void in
                                                                            })
                                                                    })
                                                                })
                                                        })
                                                })
                                        })
                                })
                        })
                })
        })
    }
}

extension UIView {
    func setScale(x: CGFloat) {
        self.transform = CGAffineTransformMakeScale(x, x)
    }
}