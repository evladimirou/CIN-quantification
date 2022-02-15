function [pixelCoords,clusterImg,candPix]=getClusterPixels(img,clusterPos,window,visual)
  % clusterPos: coordinates of pixels in cluster (nx3)
  if nargin<4
    visual = 0;
  end

  minPos = max(1,floor(min(clusterPos,[],1)-window));
  maxPos = min(size(img),ceil(max(clusterPos,[],1)+window));

  [x,y,z] = ndgrid(minPos(1):maxPos(1),minPos(2):maxPos(2),...
                   minPos(3):maxPos(3));
  pixelCoords = [x(:) y(:) z(:)];

  if (nargout>1 || visual) && nargin>1
    % Max project.
    clusterImg = max(img(minPos(1):maxPos(1),minPos(2):maxPos(2),minPos(3):maxPos(3)),[],3);
    candPix = round(bsxfun(@minus,clusterPos(:,1:2),minPos(1:2))+1);
  end

  if visual
    figure(1);

    % Make 3 layers out of original image (normalized)
    img = clusterImg;
    img = img/max(img(:));
    img = repmat(img,[1 1 3]);

    % Label cluster spots
    for j=1:size(candPix,1)
      img(candPix(j,1),candPix(j,2),:)=[1 0 0];
    end
    imshow(img);
  end
end
