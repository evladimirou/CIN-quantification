function [segments,cc]=cellSegmentCnn(net, img, channel, classId, outprefix)
% inputs: img - 3D image
% outputs: segments - cell array of structure arrays of region properties for each channel
%          cc - connected region structure

if nargin<5
  outprefix = [];
end
if ndims(img)>3
  if nargin<2
    error('Need to select channel for segmentation');
  end
  img1 = img(:,:,:,channel);
else
  img1 = img;
end
sz=size(img);
if numel(sz)==3
  sz = [sz 1];
end
fprintf('Segmenting image %dx%dx%d in channel %d\n', sz(1), sz(2), sz(3), channel);

% Sanity check image.
maxvals = arrayfun(@(z) max(img1(:,:,z),[],'all'), 2:sz(3)-1);
if any(maxvals==0)
  disp('Image contains non-edge blank planes. Skipping.')
  segments = []; cc = [];
  return
end

img1mp = im2single(max(img1,[], 3));
img1mp = imresize(img1mp, net.Layers(1).InputSize(1:2), 'bilinear');
img1mp = img1mp*/mean(img1mp(:));

% Run model.
seg = semanticseg(img1mp, net, 'outputtype', 'uint8', 'executionenvironment','cpu');
cnnlab = labeloverlay(img1mp, seg,'includedlabels',2:max(seg(:)));

% Mask out unwanted classes.
seg(seg~=(classId+1)) = 0;
bw = logical(seg);

% Scale up.
bw = imresize(bw, sz(1:2), 'bicubic');
if ndims(bw)<3
  bw = repmat(bw, 1, 1, sz(3));
end

% Remove small objects.
bw = bwareaopen(bw, 5000, 6);

% Fill holes.
bw = imfill(bw, 'holes');

% Clear objects overlapping edges.
bw = imclearborder(bw, 4);

% Label distinct regions.
cc = bwconncomp(bw);

% Find bounding boxes.
for i=1:sz(4)
  segments{i} = regionprops3(cc, img(:,:,:,i), {'BoundingBox','Volume','MinIntensity',...
                                        'MeanIntensity','MaxIntensity','Centroid',...
                                        'ConvexVolume', 'EquivDiameter', 'Extent',...
                                        'PrincipalAxisLength', 'Solidity', 'SurfaceArea',...
                                        'ConvexHull'}); %, 'VoxelValues'});
  segments{i}.Channel = i*ones(height(segments{i}),1);
  segments{i}.Cell = (1:height(segments{i}))';
end
segments = cat(1, segments{:});
segments = movevars(segments, {'Cell', 'Channel'}, 'Before', 1);

% Derived properties.
segments.TotalIntensity = segments.Volume .* segments.MeanIntensity;

% Mark cells that cross image boundary (in x,y).
bb = segments.BoundingBox;
if cc.NumObjects>0
  segments.Edge = any(bb(:,1:2)<=0.5 | bb(:,1:2)+bb(:,4:5)>=sz(1:2), 2);
else
  segments.Edge = zeros(0);
end

if ~isempty(outprefix)
  L = max(labelmatrix(cc), [], 3);
  figure;
  Lc = label2rgb(L);
  imshow(Lc);
  % Extract colours so can label if different colour.
  Lc = reshape(Lc,[],3);
  Lc = Lc(~all(Lc==255,2),:);
  colours = unique(Lc, 'rows', 'stable');
  luminance = 0.2126*colours(:,1) + 0.7152*colours(:,2) + 0.0722*colours(:,3);
  for i=1:size(luminance,1)
    if segments.Edge(i)
      str = ['^' num2str(i)];
    else
      str = num2str(i);
    end
    if luminance(i)>127
      c = 'black';
    else
      c = 'white';
    end
    cen = segments.Centroid(i,1:2);
    text(cen(1),cen(2),str, 'Color',c, 'Units', 'data','Interpreter','none')
  end
  export_fig([outprefix '_segment.jpg'],'-painters');

  rgb = repmat(im2uint8(max(img(:,:,:,channel), [] ,3)), 1, 1, 3);
  rgb = imadjust(rgb,stretchlim(rgb,0.001));
  bw = boundarymask(max(L,[],3));
  rgb = imoverlay(rgb, bw, 'red');
  imwrite(rgb, [outprefix '_overlay.jpg']);

  imwrite(cnnlab, [outprefix '_cnn.jpg']);
end
