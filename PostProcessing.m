base_dir = pwd;
pred_path  = fullfile(base_dir, '3_Test', 'Results', '120Cases', 'fold');
dose_folder = fullfile(base_dir, '3_Test', 'Results', '120Cases', 'Dose');
save_dicom_path = fullfile(base_dir, '3_Test', 'Results', '120Cases', 'DICOM_Output');

if ~exist(save_dicom_path, 'dir'), mkdir(save_dicom_path); end

load(fullfile(pred_path, 'predicted_RD.mat'), 'predicted_RD');

num_cases = 24;
for i = 1:num_cases
    dcm_filename = sprintf('reggui_Lbr%d_dose1.dcm', i);
    dcm_filepath = fullfile(dose_folder, dcm_filename);
    
    if ~exist(dcm_filepath, 'file')
        warning('Original DICOM not found for case %d', i);
        continue;
    end
    
    dose_info = dicominfo(dcm_filepath);
    dose_data = dicomread(dcm_filepath);
    num_slices_target = size(dose_data, 4);

    A = predicted_RD{i};
    A(A <= 0) = 0; 

    DGSF = dose_info.DoseGridScaling;
    dose_threshold = 50; 
    A_norDose = ((A .* dose_threshold) ./ DGSF);
    RD_re3 = imresize3(A_norDose, [512, 512, 256], "box");
    RD_slice = RD_re3(:, :, 1:num_slices_target);

    predicted_dose = reshape(RD_slice, [size(RD_slice, 1), size(RD_slice, 2), 1, size(RD_slice, 3)]);
    predicted_dose = uint16(predicted_dose);

    new_dicom_info = dose_info;
    new_dicom_info.PixelData = predicted_dose;
    new_dicom_info.Rows = size(predicted_dose, 1);
    new_dicom_info.Columns = size(predicted_dose, 2);
    new_dicom_info.NumberOfFrames = size(predicted_dose, 3);

    out_dcm_file = fullfile(save_dicom_path, sprintf('predicted_dose_%d.dcm', i));
    dicomwrite(predicted_dose, out_dcm_file, new_dicom_info, 'CreateMode', 'copy');
end