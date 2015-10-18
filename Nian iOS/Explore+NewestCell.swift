//
//  Explore+NewestCell.swift
//  Nian iOS
//
//  Created by Sa on 15/10/18.
//  Copyright © 2015年 Sa. All rights reserved.
//

import Foundation
import UIKit
class NewestCell: UITableViewCell {
    var imageHead: UIImageView!
    var label: UILabel!
    var data: NSDictionary! {
        didSet {
            let url = data.stringAttributeForKey("image")
            let title = data.stringAttributeForKey("title").decode()
            imageHead.setImage("http://img.nian.so/dream/\(url)!dream")
            label.text = title
        }
    }
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None
        imageHead = UIImageView(frame: CGRectMake(0, 0, 80, 80))
        imageHead.backgroundColor = UIColor.e6()
        imageHead.layer.masksToBounds = true
        imageHead.layer.cornerRadius = SAUid() == "171264" ? 0 : 6
        contentView.addSubview(imageHead)
        
        label = UILabel(frame: CGRectMake(0, 80, 80, 34))
        label.textColor = UIColor.C33()
        label.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        contentView.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}