function img = loadImageDataset(datadir, row, col, field, channels)
% Load image data

% Find files.
dataset = [];
prefix = sprintf('r%02dc%02df%02d', row, col, field);
fprintf('Loading %s', prefix);

files = dir(fullfile(datadir, [prefix '*']));
% Go over files in directory.
for i=1:length(files)
  f = files(i);
  if f.isdir || f.name(1)=='.' || ~(strcmp(f.name(end-3:end),'tiff') || strcmp(f.name(end-2:end),'tif'))
    continue
  end
  s = regexp(f.name, 'r([\d]+)c([\d]+)f([\d]+)p([\d]+)-ch([\d]+)','tokens');
  if ~isempty(s)
    dataset = [dataset; j str2double(s{1})];
  end
end

% Plane/channel
if nargin>4 && ~isempty(channels)
  dataset = dataset(ismember(dataset(:,6), channels),:);
end
zc = unique(dataset(:,[5 6]),'rows');
sizez = max(zc(:,1));
channels = unique(zc(:,2));
sizec = length(channels);


for c=1:sizec
  ch = channels(c);
  for p=1:sizez
    data = imread(fullfile(datadir, [prefix, sprintf('p%02d-ch%dsk1fk1fl1.tiff',p,ch)]));
    fprintf('.');
    if c==1 && p==1
      [sx, sy] = size(data);
      img = zeros(sx,sy,sizez,sizec, 'uint16');
    end
    img(:,:,p,c) = data;
  end
end
fprintf('\n');



