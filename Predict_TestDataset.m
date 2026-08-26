function A = pickNumericByLastDim(S, lastDim)
    fn = fieldnames(S);
    cand = {};
    for i = 1:numel(fn)
        v = S.(fn{i});
        if isnumeric(v) && ndims(v) >= 4
            sz = size(v);
            if sz(end) == lastDim
                cand{end+1} = v;
            end
        end
    [~, idx] = max(cellfun(@numel, cand));
    A = cand{idx};
end

base_dir = pwd;
test_CT_RS_path    = fullfile(base_dir, '3_Test', '120Cases', 'CT_RS', 'test');
test_RD_path       = fullfile(base_dir, '3_Test', '120Cases', 'RD', 'test');
trained_model_path = fullfile(base_dir, '3_Test', 'Resume2', 'fold.mat');

save_path = fullfile(base_dir, 'Model', 'Resume2', 'PredictedTest');
if ~exist(save_path, 'dir'), mkdir(save_path); end

RxGy = 50; 
M = load(trained_model_path);
if isfield(M, 'trained_net')
    net = M.trained_net;
elseif isfield(M, 'net')
    net = M.net;
else
    error('Model file has neither trained_net nor net.');
end

ctFiles = dir(fullfile(test_CT_RS_path, '*.mat'));
rdFiles = dir(fullfile(test_RD_path, '*.mat'));

rdMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
for i = 1:numel(rdFiles)
    nm = lower(rdFiles(i).name);
    tok = regexp(nm, '(lbr\d+)', 'tokens', 'once');
    if isempty(tok), continue; end
    rdMap(tok{1}) = fullfile(rdFiles(i).folder, rdFiles(i).name);
end

pairs = {};
caseKeys = {};
for i = 1:numel(ctFiles)
    ctFull = fullfile(ctFiles(i).folder, ctFiles(i).name);
    nm = lower(ctFiles(i).name);
    tok = regexp(nm, '(Lbr\d+)', 'tokens', 'once');
    if isempty(tok), continue; end
    key = tok{1};

    if isKey(rdMap, key)
        pairs(end+1, :) = {ctFull, rdMap(key)};
        caseKeys{end+1, 1} = key;
    end
end

predicted_RD = cell(size(pairs, 1), 1);

for i = 1:size(pairs, 1)
    ctPath = pairs{i, 1};
    Dct = load(ctPath);
    X = pickNumericByLastDim(Dct, 5);
    X = single(X);
    if ndims(X) == 5 && size(X, 5) == 1, X = X(:, :, :, :, 1); end
    
    % Predict
    Yhat = predict(net, X);
    predicted_RD{i} = single(Yhat);
end

save(fullfile(save_path, 'predicted_RD.mat'), 'predicted_RD', 'caseKeys', 'pairs', '-v7.3');