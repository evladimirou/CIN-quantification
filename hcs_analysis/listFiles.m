function files=listFiles(data_dir, filepat)
% List files matching pattern

files = dir(fullfile(data_dir, filepat));
files = files(~cellfun('isempty', {files.date}));
if isempty(files)
  warning('No files found with pattern: %s', filepat);
end
files = {files.name};

if endsWith(filepat,'*.tiff')
  for i=1:length(files)
    files{i} = files{i}(1:9);
  end
  files = unique(files);
end
