function micronuclei=countMnTask(data_dir, out_dir, options)
    % Runs the micronuclei counting for all the files in the data_dir.
    % FIXME refactor with countTask. 
    
    restart=options.restart;
    filepat=options.filepat;
    mode=options.mode;
    mnch=options.mnch;
    model_version=options.mnmodelversion;
    
    fprintf('Using MN model version %d\n', model_version)
    if isempty(restart)
      restart=1;
      micronuclei=[];
    else
      d=load(fullfile(out_dir, 'micronuclei.mat'));
      micronuclei=d.micronuclei;
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
        img = loadImageDataset(fullfile(data_dir, 'data'), row, col, field, mnch);
      elseif endsWith(filename, '.mat')
        data = load(fullfile(data_dir, filename));
        img = data.img;
      else
        img = loadImageData(fullfile(data_dir, filename));
      end
    
      mn = countMn(img, mnch, out_dir, model_version);
      if isempty(mn)
        continue;
      end
      o = ones(height(mn),1);
      mn.PlateRow = row*o;
      mn.PlateColumn = col*o;
      mn.PlateField = field*o;
    
      % Checkpoint.
      micronuclei = cat(1, micronuclei, mn);
      save(fullfile(out_dir, 'micronuclei.mat'), 'micronuclei');
    end
    fprintf('\n');
    
    save(fullfile(out_dir, 'micronuclei.mat'), 'micronuclei', 'options');
    writetable(micronuclei, fullfile(out_dir, 'micronuclei.csv'));
