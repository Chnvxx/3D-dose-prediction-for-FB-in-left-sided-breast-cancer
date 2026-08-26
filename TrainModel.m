base_dir = pwd;
train_val_CT_RS_path = fullfile(base_dir, '2_Model', '120Cases', 'CT_RS', 'train_val');
train_val_RD_path    = fullfile(base_dir, '2_Model', '120Cases', 'RD', 'train_val');

model_path = fullfile(base_dir, '2_Model', 'CODE', 'U-net', 'U_net_3D_128_5Layer.mat');
save_path  = fullfile(base_dir, '2_Model', 'Results', '120Case', 'Training_Results');
if ~exist(save_path, 'dir'), mkdir(save_path); end

train_val_CT_RS_files = dir(fullfile(train_val_CT_RS_path, '*.mat'));
train_val_RD_files    = dir(fullfile(train_val_RD_path, '*.mat'));

train_val_CT_RS_paths = fullfile(train_val_CT_RS_path, {train_val_CT_RS_files.name});
train_val_RD_paths    = fullfile(train_val_RD_path, {train_val_RD_files.name});

[train_val_CT_RS_data, train_val_RD_data] = loadData(train_val_CT_RS_paths, train_val_RD_paths);

loaded_model = load(model_path);
lgraph = loaded_model.lgraph_128_5layer;

num_folds = 5;
for fold = 1:num_folds
    fprintf('>>> Training Fold %d\n', fold);
    
    cv = cvpartition(numel(train_val_CT_RS_data), 'KFold', num_folds);
    train_indices = training(cv, fold);
    val_indices   = test(cv, fold);

    fold_train_CTRS_data = train_val_CT_RS_data(train_indices);
    fold_train_RD_data   = train_val_RD_data(train_indices);
    fold_val_CTRS_data   = train_val_CT_RS_data(val_indices);
    fold_val_RD_data     = train_val_RD_data(val_indices);

    training_CTRS_dataset = cell2mat(fold_train_CTRS_data{1});
    for i = 2:numel(fold_train_CTRS_data)
        training_CTRS_dataset = cat(5, training_CTRS_dataset, cell2mat(fold_train_CTRS_data{i}));
    end
    
    training_RD_dataset = cell2mat(fold_train_RD_data{1});
    for i = 2:numel(fold_train_RD_data)
        training_RD_dataset = cat(5, training_RD_dataset, cell2mat(fold_train_RD_data{i}));
    end
    
    val_CTRS_dataset = cell2mat(fold_val_CTRS_data{1});
    for i = 2:numel(fold_val_CTRS_data)
        val_CTRS_dataset = cat(5, val_CTRS_dataset, cell2mat(fold_val_CTRS_data{i}));
    end
    
    val_RD_dataset = cell2mat(fold_val_RD_data{1});
    for i = 2:numel(fold_val_RD_data)
        val_RD_dataset = cat(5, val_RD_dataset, cell2mat(fold_val_RD_data{i}));
    end

    trained_net = trainModel(training_CTRS_dataset, training_RD_dataset, val_CTRS_dataset, val_RD_dataset, lgraph);
    save(fullfile(save_path, sprintf('trained_model_fold_%d.mat', fold)), 'trained_net');
end