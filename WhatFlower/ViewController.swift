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
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
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
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("could not classify image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.searchWikipedia(title: classification.identifier) { (extract) in
                self.label.text = extract
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: convertedImage)
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
    
    func searchWikipedia(title: String, completion: @escaping (String) -> Void)
    {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : title,
            "indexpageids" : "",
            "redirects" : "1",
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { response in
            if !response.result.isSuccess {
                return
            }
            
            guard let value = response.result.value else {
                print("Error could not get value.")
                return
            }
            
            let json = JSON(value)
            let pageId = json["query"]["pageids"][0].string!
            guard let extract = json["query"]["pages"][pageId]["extract"].string else {
                fatalError("could not get extract from json.")
            }
            
            completion(extract)
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
