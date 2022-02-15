function mn=countMn(img, channel, out_dir, model_version)
% inputs: img - 3D image

if nargin<4
  model_version=1;
end

switch model_version
case 1
  model = 'model_mae1_3ch.pt';
case 2
  model = 'model_inc039.pt';
end

% Ensure clean tmp folder.
tmp_dir = fullfile(out_dir, 'imgtmp');
status = rmdir(tmp_dir, 's');
status = mkdir(tmp_dir);


if ndims(img)>3
  if nargin<2
    error('Need to select channel for counting');
  end
  img = img(:,:,:,channel);
end

fprintf('Saving micronuclei image');
img = max(img, [], 3);

% Save img to mat.
save(fullfile(tmp_dir, 'mn.mat'), 'img');

fprintf('\nCounting...');
% Call Python to evaluate model.
[status, out] = system(sprintf('python ../hcs_nn_mn/hcs_nn_mn_eval.py %s -m %s', tmp_dir, model));

% Parse model output.
lines = splitlines(out);
count = [];
for i=1:length(lines)
  if ~startsWith(lines{i}, 'Image')
    continue
  end
  s = split(lines{i}, ':');
  img_count = str2double(s{2});
  count = [count; img_count];
end
fprintf('done (%.2f)\n', count(end));


if isempty(count)
  mn = [];
else
  % Build table.
  mn = array2table(count, 'VariableNames', {'Count'});
end
