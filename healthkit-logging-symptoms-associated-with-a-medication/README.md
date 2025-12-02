# Logging symptoms associated with a medication 

Fetch medications and dose events from the HealthKit store, and create symptom samples to associate with them.

## Overview

> Note: This sample code project is associated with WWDC25 session 321: [Meet the HealthKit Medications API](https://developer.apple.com/wwdc25/321/).

## Configure the sample code project

Before you run the sample code project:

1. Open the sample with the latest version of Xcode. 
2. Set the developer team for the project target to let Xcode automatically manage the provisioning profile. For more information, see [Set the bundle ID](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution#Set-the-bundle-ID) and [Assign the project to a team](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution#Assign-the-project-to-a-team).

To play with the sample app:

1. Launch the Health app on your iPhone, select the Browse tab, and tap Medications.

2. In the Medications view, add Acetaminophen 500 mg Oral Capsule, Carbinoxamine Maleate Biphasic Release Oral Capsule (10 mg), or Ciprofloxacin Injection 200 mg/20 mL as a sample medication. The sample app associates symptoms with these three medications using their RxNorm codes by mapping the codes to their symptoms in the `SideEffects` dictionary in `SideEffects.swift`.

3. For each medication, log a dose as *taken* in the As Needed Medications section. The sample app forms a predicate to only look for doses marked as `taken`.

4. Build and run the sample app on the iPhone to see the medication list after providing authorization. Tap a medication to see the most-recent dose event and associated symptoms. When tapping a medication, an additional authorization sheet prompts for authorization to access symptoms data.

5. To add more medications in the Health app and view them in the sample app, add their RxNorm codes to the `SideEffects` dictionary, along with their associated symptoms. For instance, for piroxicam, the RxNorm code is 105929, and the symptoms can be headache, loss of appetite, and nausea. To view the symptoms, modify `SideEffects` by adding the following code:

```
"105929": [SymptomModel(name: "Headache", categoryID: .headache),
			SymptomModel(name: "Diarrhea", categoryID: .diarrhea),
			SymptomModel(name: "Nausea", categoryID: .nausea)]
```

6. Log doses for medications over time, and observe them in the Charts tab of the sample app.
