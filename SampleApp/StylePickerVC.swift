//
//  StylePickerVC.swift
//  ios-sdk
//
//  Created by Matt Smollinger on 10/3/17.
//  Copyright © 2017 Mapzen. All rights reserved.
//

import UIKit
import Mapzen_ios_sdk

class StylePickerVC: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {


  @IBOutlet var styleSheetPicker: UIPickerView!
  @IBOutlet var colorPicker: UIPickerView!

  @IBOutlet var levelOfDetailText: UITextField!
  @IBOutlet var labelDensityText: UITextField!

  @IBOutlet var transitOverlaySwitch: UISwitch!
  @IBOutlet var bikeOverlaySwitch: UISwitch!
  @IBOutlet var walkingOverlaySwitch: UISwitch!

  weak var mapController : SampleMapViewController?
  var currentSelectedStyle: StyleSheet = BubbleWrapStyle()
  var currentColor: String = ""
  var currentLabelLevel: Int = 0
  var currentDetailLevel: Int = 0

  var availableStyles : [ String : StyleSheet ] = ["Bubble Wrap" : BubbleWrapStyle(),
                         "Cinnabar" : CinnabarStyle(),
                         "Refill" : RefillStyle(),
                         "Walkabout" : WalkaboutStyle(),
                         "Zinc" : ZincStyle()]

  //MARK:- Internal Funcs


  func transitOverlaySwitchChanged(switchState: UISwitch) {
    mapController?.showTransitOverlay = switchState.isOn
  }
  func bikeOverlaySwitchChanged(switchState: UISwitch) {
    if switchState.isOn {
      walkingOverlaySwitch.setOn(false, animated: true)
      mapController?.showWalkingPathOverlay = false
    }
    mapController?.showBikeOverlay = switchState.isOn
  }
  func walkingOverlaySwitchChanged(switchState: UISwitch) {
    if switchState.isOn {
      bikeOverlaySwitch.setOn(false, animated: true)
      mapController?.showBikeOverlay = false
    }
    mapController?.showWalkingPathOverlay = switchState.isOn
  }

  func setUIStateForStyle(styleSheet: StyleSheet) {
    colorPicker.reloadAllComponents()
    if styleSheet.availableDetailLevels > 0 {
      levelOfDetailText.text = String(styleSheet.detailLevel)
      levelOfDetailText.isEnabled = true
    } else {
      levelOfDetailText.text = "N/A"
      levelOfDetailText.isEnabled = false
    }

    if styleSheet.availableLabelLevels > 0 {
      labelDensityText.text = String(styleSheet.labelLevel)
      labelDensityText.isEnabled = true
    } else {
      labelDensityText.text = "N/A"
      labelDensityText.isEnabled = false
    }
  }

  //MARK:- Controller Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    transitOverlaySwitch.setOn(mapController!.showTransitOverlay, animated: true)
    transitOverlaySwitch.addTarget(self, action: #selector(transitOverlaySwitchChanged(switchState:)), for: .valueChanged)

    bikeOverlaySwitch.setOn(mapController!.showBikeOverlay, animated: true)
    bikeOverlaySwitch.addTarget(self, action: #selector(bikeOverlaySwitchChanged(switchState:)), for: .valueChanged)

    walkingOverlaySwitch.setOn(mapController!.showWalkingPathOverlay, animated: true)
    walkingOverlaySwitch.addTarget(self, action: #selector(walkingOverlaySwitchChanged(switchState:)), for: .valueChanged)

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    currentSelectedStyle = appDelegate.selectedMapStyle
    currentColor = currentSelectedStyle.currentColor
    currentDetailLevel = currentSelectedStyle.detailLevel
    currentLabelLevel = currentSelectedStyle.labelLevel

    setUIStateForStyle(styleSheet: currentSelectedStyle)
  }


  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let values = Array(availableStyles.values)

    //Set the style picker to the correct current style
    let index = values.index { (style) -> Bool in
      style.relativePath == currentSelectedStyle.relativePath
    }
    if let unwrappedIndex = index {
      styleSheetPicker.selectRow(unwrappedIndex, inComponent: 0, animated: false)
    }

    //Set the color picker to the correct current color (assuming we have one)
    if currentSelectedStyle.availableColors.count > 0 &&
      !currentSelectedStyle.currentColor.isEmpty {
      if let colorIndex = currentSelectedStyle.availableColors.index(of: currentSelectedStyle.currentColor) {
        colorPicker.selectRow(colorIndex, inComponent: 0, animated: false)
      }
    }
  }
  func saveTextField(_ textField: UITextField) {
    guard let text = textField.text, var level = Int(text) else { return }

    if level > currentSelectedStyle.availableLabelLevels { level = currentSelectedStyle.availableLabelLevels }
    if level < 0 { level = 0 }

    if textField == levelOfDetailText {
      currentSelectedStyle.detailLevel = level
    }

    if textField == labelDensityText {
      currentSelectedStyle.labelLevel = level
    }
  }

  //MARK:- Interface Builder
  @IBAction func savePressed(_ sender: Any) {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    saveTextField(labelDensityText)
    saveTextField(levelOfDetailText)
    appDelegate.selectedMapStyle = currentSelectedStyle
    self.dismiss(animated: true, completion: nil)
  }
  @IBAction func cancelPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  //MARK:- Picker View
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    if pickerView == styleSheetPicker {
      return availableStyles.count
    }
    if pickerView == colorPicker {
      let styleKeys = Array(availableStyles.keys)
      if currentSelectedStyle.availableColors.count > 0 &&
        styleKeys[styleSheetPicker.selectedRow(inComponent: 0)] != "Zinc"{
        // We want to return 1 in the event we have no colors to show "No Colors" so just need this
        return currentSelectedStyle.availableColors.count
      }
    }
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    let styleKeys = Array(availableStyles.keys)
    if pickerView == styleSheetPicker {
      return styleKeys[row]
    }
    if pickerView == colorPicker {
      if currentSelectedStyle.availableColors.count == 0 ||
        styleKeys[styleSheetPicker.selectedRow(inComponent: 0)] == "Zinc" {
        return "N/A"
      }
      return currentSelectedStyle.availableColors[row]
    }

    return "???"
  }


  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    if pickerView == styleSheetPicker {
      let keys = Array(availableStyles.keys)
      let style = availableStyles[keys[row]]
      guard let unwrappedStyle = style else { return }
      currentSelectedStyle = unwrappedStyle
      setUIStateForStyle(styleSheet: unwrappedStyle)
    }
    if pickerView == colorPicker {
      if currentSelectedStyle.availableColors.count == 0 { return }
      currentSelectedStyle.currentColor = currentSelectedStyle.availableColors[row]
    }
  }
}
