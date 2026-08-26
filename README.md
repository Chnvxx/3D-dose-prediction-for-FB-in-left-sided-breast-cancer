# 3D-dose-prediction-for-FB-in-left-sided-breast-cancer
MATLAB implementation of 3D U-Net dose prediction and workflow for left-sided breast cancer radiotherapy.

## Workflow / How to Run
1. **PreProcessing.m**: Prepare and pad CT, Dose, and RT Structure sets.
2. **TrainModel.m**: Train the 3D U-Net model using K-fold cross-validation.
3. **Predict_TestDataset.m**: Perform dose prediction on the test dataset.
4. **PostProcessing.m**: Convert predicted matrices back into DICOM format for evaluation in REGGUI.
