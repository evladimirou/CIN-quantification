function spots=countTask(data_dir, segment_dir, out_dir, options)
% Runs the centromere counting for all the files in the data_dir.

restart=options.restart;
filepat=options.filepat;
mode=options.mode;
segmentch=options.segmentch;
spotch=options.spotch;
version=options.version;
verbose=options.verbose;

if isempty(restart)
  restart=1;
  spots=[];
else
  d=load(fullfile(out_dir, 'spots.mat'));
  spots=d.spots;
end

[~,~] = mkdir(out_dir);

% Load segment data.
d = load(fullfile(segment_dir, 'segments.mat'));
segments = d.segments;

d = listFiles(data_dir, filepat);
for i=restart:length(d)
  % Parse filename.
  filename = d{i};
  [row,col,field] = parseFilename(filename, mode);
  if isempty(row)
    fprintf('Skipping %s\n', filename);
    continue
  end

  % Load data.
  fprintf('Loading file %d of %d: %s\n', i, length(d), filename);
  if strcmp(filepat, 'data/*.tiff')
    img = loadImageDataset(fullfile(data_dir, 'data'), row, col, field, spotch);
  elseif endsWith(filename, '.mat')
    data = load(fullfile(data_dir, filename));
    img = data.img;
  else
    img = loadImageData(fullfile(data_dir, filename));
  end

  % Extract segments.
  seg = segments(segments.PlateRow==row & segments.PlateColumn==col & ...
                 segments.PlateField==field & segments.Channel==segmentch,:);

  out_file_prefix = fullfile(out_dir, strrep(filename, '.ome.tiff', ''));
  countFn = str2func(['countSpots_' version]);
  sp = countFn(img, seg, spotch, out_file_prefix, verbose, options);
  if isempty(sp)
    continue;
  end
  o = ones(height(sp),1);
  sp.PlateRow = row*o;
  sp.PlateColumn = col*o;
  sp.PlateField = field*o;

  % Checkpoint.
  spots = cat(1, spots, sp);
  save(fullfile(out_dir, 'spots.mat'), 'spots');
end
fprintf('\n');

save(fullfile(out_dir, 'spots.mat'), 'spots', 'options');
writetable(spots, fullfile(out_dir, 'spots.csv'));
