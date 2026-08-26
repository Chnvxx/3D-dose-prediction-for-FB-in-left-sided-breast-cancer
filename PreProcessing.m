for i = 1:120
    preprocess_CT(i);
    preprocess_dose(i);
    preprocess_structure(i, 'BODY');
    preprocess_structure(i, 'Heart');
    preprocess_structure(i, 'Lung_Lt');
    preprocess_structure(i, 'PTV');
end

function preprocess_CT(patient_number)
    base_dir = pwd;
    dicom_folder = fullfile(base_dir, 'CaseProject', 'RT', 'CT', ['reggui_Lbr', num2str(patient_number)]);
    dicom_files = dir(fullfile(dicom_folder, '*.dcm'));
    num_slices = numel(dicom_files);
    
    ct_128 = zeros(128, 128, min(256, num_slices));
    for i = 1:min(256, num_slices)
        ct = dicomread(fullfile(dicom_folder, dicom_files(i).name));
        ct_128(:,:,i) = imresize(ct, [128, 128]);
    end

    ct_rescaled = rescale(ct_128);

    if num_slices < 256
        num_slices_to_add = 256 - num_slices;
        additional_slices = zeros(128, 128, num_slices_to_add);
        ct_rescaled(:,:,num_slices+1:256) = additional_slices;
    end   

    ct_Re3 = imresize3(ct_rescaled, [size(ct_rescaled,1), size(ct_rescaled,2), 128]);
    ct_images = rescale(ct_Re3);

    save_path = fullfile(base_dir, 'Output_Matrix', 'CT');
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    save(fullfile(save_path, ['Lbr', num2str(patient_number), '_CT.mat']), 'ct_images');
end

function preprocess_dose(patient_id)
    base_dir = pwd;
    dose_folder = fullfile(base_dir, 'CaseProject', 'RT', 'RD', ['Lbr', num2str(patient_id), '_dose']);
   
    dicom_files = dir(fullfile(dose_folder, '*.dcm'));
    dose_data = dicomread(fullfile(dose_folder, dicom_files(1).name));
    
    num_slices = size(dose_data, 4);
    dose_info = dicominfo(fullfile(dose_folder, dicom_files(1).name));
    dose_data = permute(dose_data, [1, 2, 4, 3]);

    RD_resize = double(imresize(dose_data, [128, 128], "Method", "bicubic"));
    DGSF = dose_info.DoseGridScaling;
    RD_Gy = RD_resize .* DGSF;   
    RD_nor = RD_Gy ./ 50;
    doses = reshape(RD_nor, [size(RD_nor, 1), size(RD_nor, 2), size(RD_nor, 3), 1]);

    if num_slices < 256
        num_slices_to_add = 256 - num_slices;
        additional_slices = zeros(128, 128, num_slices_to_add, 1);
        doses(:,:,num_slices+1:256,1) = additional_slices;
    end
    
    doses = imresize3(doses, [size(doses,1), size(doses,2), 128], "Method", "cubic");
    doses(doses <= 0) = 0;

    save_path = fullfile(base_dir, 'Output_Matrix', 'RD');
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    save(fullfile(save_path, ['Lbr', num2str(patient_id), '_dose.mat']), 'doses');
end

function preprocess_structure(patient_number, structure_name)
    base_dir = pwd;
    dicom_folder = fullfile(base_dir, 'CaseProject', 'RT', 'RS', structure_name, ['reggui_Lbr', num2str(patient_number), '_', structure_name]);
    
    dicom_files = dir(fullfile(dicom_folder, '*.dcm'));
    num_slices = numel(dicom_files);
    
    contour_128 = zeros(128, 128, min(256, num_slices));
    for i = 1:min(256, num_slices)
        contour = dicomread(fullfile(dicom_folder, dicom_files(i).name));
        contour_128(:,:,i) = imresize(contour, [128, 128]);
    end
    
    min_value = min(contour_128(:));
    RS_bi = contour_128 - min_value;
    
    if num_slices < 256
        num_slices_to_add = 256 - num_slices;
        additional_slices = zeros(128, 128, num_slices_to_add);
        RS_bi(:,:,num_slices+1:256) = additional_slices;
    end   
    
    contours = imresize3(RS_bi, [size(RS_bi,1), size(RS_bi,2), 128]);
    
    if strcmp(structure_name, 'PTV')
        contours(contours == 1) = 50;
        contours(contours == 0) = 0;
    end

    save_path = fullfile(base_dir, 'Output_Matrix', 'RS', structure_name);
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    save(fullfile(save_path, ['Lbr', num2str(patient_number), '_', structure_name, '.mat']));
end