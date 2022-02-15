function segments=segmentTask(data_dir, out_dir, options)
% Runs the cell segmentation for all the files in the data_dir.

restart=options.restart;
filepat=options.filepat;
mode=options.mode;
segmentch=options.segmentch;
adaptivesegment=options.adaptivesegment;

if options.cnn
  switch options.classid
    case 1
      n = load('cnn_model.mat');
    case 2
      n = load('model_unet2d_micro.mat');
    otherwise
      error('No model for classid');
  end
  net = n.net;
end

if isempty(restart)
  restart=1;
  segments=[];
else
  segmentFile = fullfile(out_dir, 'segments.mat');
  if exist(segmentFile, 'file')
    d=load(segmentFile);
    segments=d.segments;
  else
    fprintf('Failed to load %s. Restarting at %d anyway.\n', segmentFile, restart);
    segments=[];
  end
end

[~,~] = mkdir(out_dir);
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
    img = loadImageDataset(fullfile(data_dir, 'data'), row, col, field);
  elseif endsWith(filename, '.mat')
    data = load(fullfile(data_dir, filename));
    img = data.img;
  else
    img = loadImageData(fullfile(data_dir, filename));
  end

  % Check image quality.
  en = entropy(img(:,:,:,segmentch));
  if en<0.5
    fprintf('Image entropy too low, skipping: %.4f\n', en);
    continue
  end

  fprintf('Segmenting cells\n');
  out_file_prefix = fullfile(out_dir, strrep(filename, '.ome.tiff', ''));
  if options.cnn
    seg = cellSegmentCnn(net, img, segmentch, options.classid, out_file_prefix);
  else
    seg = cellSegment(img, segmentch, out_file_prefix, adaptivesegment);
  end
  if isempty(seg)
    fprintf('No segments. Skipping %s\n', filename);
    continue
  end
  o = ones(height(seg),1);
  seg.PlateRow = row*o;
  seg.PlateColumn = col*o;
  seg.PlateField = field*o;
  seg.Filename = repmat({filename}, height(seg), 1);

  % Checkpoint.
  segments = cat(1, segments, seg);
  save(fullfile(out_dir, 'segments.mat'), 'segments');
end

save(fullfile(out_dir, 'segments.mat'), 'segments', 'options');
segments.ConvexHull = []; % Cannot write hull list in CSV.
writetable(segments, fullfile(out_dir, 'segments.csv'));
