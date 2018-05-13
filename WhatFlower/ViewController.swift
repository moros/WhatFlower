//
//  ViewController.swift
//  WhatFlower
//
//  Created by Doug Mason on 5/6/18.
//  Copyright © 2018 Doug Mason. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else {
            print("There was an error picking the image.")
            return
        }
        
        imageView.image = image
        imagePicker.dismiss(animated: true, completion: nil)
        
        detect(flowerImage: image)
    }
    
    func detect(flowerImage image: UIImage)
    {
        guard let convertedImage = CIImage(image: image) else {
            fatalError("cannot convert to CIImage.")
        }
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            let classification = request.results?.first as? VNClassificationObservation
            self.navigationItem.title = classification?.identifier.capitalized
        }
        
        let handler = VNImageRequestHandler(ciImage: convertedImage)
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
    
    @IBAction func cameraBarButtonPressed(_ sender: UIBarButtonItem)
    {
        let alertController = UIAlertController(title: "What should the source be for the image picker?",
                                                message: "The image picker has different source options, camera, photo library or saved photos album.",
                                                preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: "Saved Photos Album", style: .default, handler: { (action) in
            self.imagePicker.sourceType = .savedPhotosAlbum
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
}
