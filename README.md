# 3D-dose-prediction-for-FB-in-left-sided-breast-cancer
MATLAB implementation of 3D U-Net dose prediction and workflow for left-sided breast cancer radiotherapy.

## Workflow / How to Run
1. **PreProcessing.m**: Prepare and pad CT, Dose, and RT Structure sets.
2. **TrainModel.m**: Train the 3D U-Net model using K-fold cross-validation.
3. **Predict_TestDataset.m**: Perform dose prediction on the test dataset.
4. **PostProcessing.m**: Convert predicted matrices back into DICOM format.
After model prediction, the predicted dose matrices were converted back into DICOM format, and dosimetric evaluations (DVH parameters) were performed using the REGGUI software.
