function [img,md] = loadImageData(filename, dimOrder)
% Load image data

if nargin<2
  dimOrder = [];
end


data = bfopen(filename);
md = data{4};
[sizex,sizey] = size(data{1}{1,1});
sizez = md.getPixelsSizeZ(0).getValue;
sizec = md.getPixelsSizeC(0).getValue;
sizet = md.getPixelsSizeT(0).getValue;
img = zeros(sizex,sizey,sizez,sizec,sizet, 'uint16');

% Setup loops to read in stored dimension order.
if isempty(dimOrder)
  dimOrder = lower(char(md.getPixelsDimensionOrder(0)));
else
  dimOrder = lower(dimOrder);
end
for i=1:3
  loop(i) = eval(['size' dimOrder(i+2)]);
end
% Map to return dimension order XYZCT.
dimIdx(1) = find(dimOrder=='z')-2;
dimIdx(2) = find(dimOrder=='c')-2;
dimIdx(3) = find(dimOrder=='t')-2;

ptr = 1;
for i1=1:loop(3)
  for i2=1:loop(2)
    for i3=1:loop(1)
      idx = {i3,i2,i1};
      idx = idx(dimIdx);
      [z,c,t] = deal(idx{:});
      img(:,:,z,c,t) = data{1}{ptr};
      ptr = ptr + 1;
    end
  end
end
