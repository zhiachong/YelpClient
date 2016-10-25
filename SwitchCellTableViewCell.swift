//
//  SwitchCellTableViewCell.swift
//  Yelp
//
//  Created by Zhia Chong on 10/23/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

@objc protocol SwitchCellTableViewCellDelegate {
    @objc optional func switchCellTableViewCell(switchCellTableViewCell: SwitchCellTableViewCell, didChangeValue value: Bool)
}

class SwitchCellTableViewCell: UITableViewCell {
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var onSwitch: UISwitch!
    
    weak var delegate: SwitchCellTableViewCellDelegate?
    let key = "frame"
    class var defaultHeight: Float {get { return 44 }}

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        onSwitch.addTarget(self, action: #selector(SwitchCellTableViewCell.onSwitchTapped), for: UIControlEvents.valueChanged)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func onSwitchTapped() {
        if delegate != nil {
            delegate?.switchCellTableViewCell!(switchCellTableViewCell: self, didChangeValue: onSwitch.isOn)
        }
    }
    
    func watchFrameChange() {
        addObserver(self, forKeyPath: key, options: .new, context: nil)
    }
    
    func unwatchFrameChange() {
        removeObserver(self, forKeyPath: key)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == key) {
            
        }
    }

}
