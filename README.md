# Fall Logger

## Description

- "Fall Logger" App is monitoring the device falls, save them locally in json file and show an alert.
- The app uses a trained Model (cf: FallActivityClassifier) with CoreML to determine if the phone activity is falling or not.
- You can access the CreatML project at the root of the project folder (cf. "MachineLearning/FallActivityClassifier.mlproj").
- If a new model is generated with the name "FallActivityClassifier", it will replace automatically the previous one used by the app.

## Requirements
- iOS Deployement Target: 15.3
- XCode Version: 13.3

## TODO
- [ ] Finish writing Unit testing for different classes.
- [ ] Log accelerometer in background (cf. Using the locationManager trick 🪄).
- [ ] There's some operation queues that need better handling (cf. FallDetectorManager).
- [ ] Push local notification when fall detected in background.
- [ ] Improve UI.
- [ ] Definitely need to improve trained model.




