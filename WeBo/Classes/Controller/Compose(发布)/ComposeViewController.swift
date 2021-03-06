//
//  ComposeViewController.swift
//  WeBo
//
//  Created by Apple on 16/11/9.
//  Copyright © 2016年 叶炯. All rights reserved.
//

import UIKit
import SVProgressHUD
private let picPickerCell = "picPickerCell"
private let edgeMargin: CGFloat = 15
class ComposeViewController: UIViewController {

    //MARK:- 懒加载属性
    fileprivate lazy var textView: ComposeTextView = ComposeTextView()
    fileprivate lazy var titleView: ComposeTitleView = ComposeTitleView()
    fileprivate lazy var toolBarBottom: UIToolbar = UIToolbar()
    fileprivate lazy var images: [UIImage] = [UIImage]()

    fileprivate lazy var emoticonVc : EmoticonController = EmoticonController {[weak self] (emoticon) -> () in
        self?.textView.insertEmoticon(emoticon)
        self?.textViewDidChange(self!.textView)

    }
    //MARK:- 定义全局函数
    
    var PicPickerCollectionView: UICollectionView?
    
    //MARK:- 系统回掉函数
    override func viewDidLoad() {
        super.viewDidLoad()

        //设置导航条
        setupNavigationBar()
        //添加 UICollextionView
        setupPicPickerCollectionView()
        
        //设置 toolBar工具条
        setupToolsBarBottom()
        
        // 监听键盘通知
        NotificationCenter.default.addObserver(self, selector: #selector(ComposeViewController.keyboardWillChangeFrame(note:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        // 监听 collectionView 的点击
        NotificationCenter.default.addObserver(self, selector: #selector(ComposeViewController.addPhotoClick), name: NSNotification.Name(rawValue: PicPickerAddPhotoNote), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    //MARK: - 释放函数
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
}

//MARK:- UI界面相关
extension ComposeViewController {

    // 1. 设置左右的 item
    fileprivate func setupNavigationBar() {
        self.automaticallyAdjustsScrollViewInsets = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(ComposeViewController.closeItemBtnClick))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "发布", style: .plain, target: self, action: #selector(ComposeViewController.sendItemBtnClick))
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.title = "发微博"
        
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        navigationItem.titleView = titleView

        view .addSubview(textView)

        textView.snp.makeConstraints { (make) in
            make.top.equalTo(8)
            make.left.equalTo(view.snp.left).offset(8)
            make.bottom.equalTo(view.snp.bottom).offset(0)
            make.right.equalTo(view.snp.right).offset(-8)
        }
        textView.delegate = self
        //设置 UITextView 的滚动不受限制
        textView.alwaysBounceVertical = true
    }
    
    fileprivate func setupToolsBarBottom() {
        view .addSubview(toolBarBottom)
        toolBarBottom.backgroundColor = UIColor.darkGray
        // 设置控件的 frame

        toolBarBottom.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(0)
            make.height.equalTo(44)
        }
        // 定义 toolBar中 titles
        let titleImgs = ["compose_toolbar_picture.png","compose_mentionbutton_background.png","compose_trendbutton_background.png","compose_emoticonbutton_background.png","compose_keyboardbutton_background.png"]
        
        // 遍历标题,创建 item
        var index = 0
        var tempItem = [UIBarButtonItem]()
        
        for titleImg in titleImgs {
            
             let imageNormal = UIImage(named: titleImg)?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            
            let item = UIBarButtonItem(image: imageNormal, style: .plain, target: self, action: #selector(ComposeViewController.itemBtnClick(sender:)))
            
            item.tag = index
            index += 1
            //添加弹簧
            tempItem.append(item)
            tempItem.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        }
        
        // 设置 toolBar的 item 数组
        tempItem.removeLast()
        toolBarBottom.items = tempItem
    }
   
}

//MARK:- 设置picPickCollectionView
extension ComposeViewController {

    fileprivate func setupPicPickerCollectionView() {
        
        let layout = UICollectionViewFlowLayout()
        PicPickerCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        let itemWH = (UIScreen.main.bounds.width - 4 * edgeMargin) / 3
        
        layout.itemSize = CGSize(width: itemWH, height: itemWH)
        layout.minimumLineSpacing = edgeMargin
        layout.minimumInteritemSpacing = edgeMargin
        layout.scrollDirection = .vertical
        //设置 collectionView 的属性
        PicPickerCollectionView?.register(UINib(nibName: "PicPickerViewCell", bundle: nil), forCellWithReuseIdentifier: picPickerCell)
        PicPickerCollectionView?.dataSource = self
        
        PicPickerCollectionView?.contentInset = UIEdgeInsetsMake(edgeMargin, edgeMargin, 0, edgeMargin)

        self.view.addSubview(PicPickerCollectionView!)
        PicPickerCollectionView!.snp.updateConstraints({ (make) in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(0)
            make.height.equalTo(0)
        })
    }
}

//MARK:- collectionView的代理和数据源方法
extension ComposeViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: picPickerCell, for: indexPath) as! PicPickerViewCell
        cell.backgroundColor = UIColor.red
        cell.delegate = self
        cell.image = indexPath.item <= images.count - 1 ? images[indexPath.item] : nil
        return cell
    }
}

//MARK:- 事件的监听
extension ComposeViewController {

    @objc fileprivate func closeItemBtnClick() {
    
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func sendItemBtnClick() {
        // 0.键盘退出
        textView.resignFirstResponder()
        // 1.获取发送微博的微博正文
        let statusText = textView.getEmoticonString()
        // 2.定义回调的闭包
        let finishedCallback = { (isSuccess : Bool) -> () in
            if !isSuccess {
                SVProgressHUD.showError(withStatus: "发送微博失败")
                return
            }
            SVProgressHUD.showSuccess(withStatus: "发送微博成功")
            self.dismiss(animated: true, completion: nil)
        }
        // 3.获取用户选中的图片
        if let image = images.first {
            NetworkTools.shareInstance.sendStatus(statusText: statusText, image: image, isSuccess: finishedCallback)
        } else {
            NetworkTools.shareInstance.sendStatus(statusText: statusText, isSuccess: finishedCallback)
        }


    }
    
    //监听键盘的事件
    func keyboardWillChangeFrame(note: Notification) {
        
//        print(note.userInfo ?? "")
        // 1.获取动画执行的时间
        let duration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        
        // 2.获取键盘最终 Y值
        let endFrame = (note.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let y = endFrame.origin.y
        
        //计算工具栏距离底部的间距
        let margin = UIScreen.main.bounds.height - y
//        print(margin)
        // 更新约束,执行动画
        toolBarBottom.snp.updateConstraints { (make) in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(44)
            make.bottom.equalTo(-margin)
        }
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    //toolbar的时间监听
    @objc func itemBtnClick(sender: UIBarButtonItem) {
    
        print(sender.tag)
        switch sender.tag {
        case 0:
            textView.resignFirstResponder()
            //更新 picCollectionView 的约束 执行动画
            PicPickerCollectionView!.snp.updateConstraints({ (make) in
                make.left.equalTo(0)
                make.right.equalTo(0)
                make.bottom.equalTo(0)
                make.height.equalTo(UIScreen.main.bounds.height * 0.65)
            })
            
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            })
        case 3:
            // 1.退出键盘
            textView.resignFirstResponder()
            
            // 2.切换键盘
            textView.inputView = textView.inputView != nil ? nil : emoticonVc.view
            
            // 3.弹出键盘
            textView.becomeFirstResponder()
          
        default:
         return
        }
    }
}

//MARK:- 获取选择照片的事件监听
extension ComposeViewController:PicPickerViewCellDelegate {
    
    @objc fileprivate func addPhotoClick() {
        
        // 1. 判断数据源是否可用
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            return
        }
        // 2.创建照片选择控制器
        let imgPicker = UIImagePickerController()
        
        // 3.设置照片源
        imgPicker.sourceType = .photoLibrary
        
        // 4.设置代理
        imgPicker.delegate = self
        
        // 弹出选着照片的控制器
        present(imgPicker, animated: true, completion: nil)
    }
    
    func didpickerDeleteBtnClick(sender: UIButton, picImage: UIImage) {
        
        //获取 image 对象所在下标值
        guard let index = images.index(of: picImage) else {
            return
        }
        //将图片从数组中删除
        images.remove(at: index)

        //刷新 collextionView
        PicPickerCollectionView?.reloadData()
    }
}

//MARK: - textView代理方法
extension ComposeViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        //hasText 系统提供的方法判断是否有没有内容
        self.textView.preloadLab.isHidden = textView.hasText
        navigationItem.rightBarButtonItem?.isEnabled = textView.hasText
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        textView.resignFirstResponder()
    }
}

//MARK:- UIImagePickerController代理方法
extension ComposeViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // 1.获取选中的照片
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // 2.展示照片
        images.append(image)
        
        PicPickerCollectionView?.reloadData()
        
        picker.dismiss(animated: true, completion: nil)
    }
}

