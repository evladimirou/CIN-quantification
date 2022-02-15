function result=runTasks(task, experiment, varargin)
% Set filepat to 'data/*.tiff' to follow symlink to raw data

if ~ismember(task, {'segment','count','mncount'})
  error(['Unrecognized task ' task]);
end

options.restart = [];
options.spotch = 2;
options.segmentch = 1;
options.mnch = options.segmentch;
options.version = 'v3';
options.mode = 'hcs';
options.filepat = [];
options.segsuffix = '';
options.spotsuffix = '';
options.mnsuffix = '';
options.adaptivesegment = 1;
options.cnn = 1;
options.classid = 1;
options.rootdir = [];
options.mnmodelversion = 2;
options.alphaF = 0.01;
options.verbose = 0;
options.maxPsfs = 2;
options = processOptions(options, varargin{:});

if isempty(options.rootdir)
  root_dir = rootDir();
else
  root_dir = options.rootdir;
end
data_dir = fullfile(root_dir, experiment);
segment_dir = fullfile(data_dir, ['segment' options.segsuffix]);

if isempty(options.filepat)
  switch options.mode
    case 'hcs'
      options.filepat = 'merge-*';
    case 'dv'
      options.filepat = '*_D3D.dv';
    otherwise
      error(['Unknown filename parsing mode: ' options.mode]);

  end
end

addpath bfmatlab;
javaaddpath bfmatlab/bioformats_package.jar
addpath export_fig;
try
  switch task
    case 'segment'
      result = segmentTask(data_dir, segment_dir, options);

    case 'count'
      spot_dir = fullfile(data_dir, ['spot' options.spotsuffix]);
      result = countTask(data_dir, segment_dir, spot_dir, options);
    case 'mncount'
      mn_dir = fullfile(data_dir, ['mn' options.mnsuffix]);
      result = countMnTask(data_dir, mn_dir, options);      
  end
catch e
  disp(getReport(e))
  if isa(e, 'matlab.exception.JavaException')
    disp('Quitting due to Java heap out of memory (return code=failed image).');
    quit(i);
  end
end

disp('Finished.')
