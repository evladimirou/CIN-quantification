function [x0,lb,ub]=guessBounds(pos,amp,clusterPixels,bgAmp,psfSigma,varargin)
  % pos: candidate maxima positions (nx3)
  % clusterPixels: coordinates of pixels comprising the cluster (nx3)

  fitPsf = 0;
  fitAmp = 0;
  if ismember('fitpsf',varargin)
    fitPsf = 1;
  end
  if ismember('fitamp',varargin)
    fitAmp = 1;
  end

  x0 = pos; % initial guess is candidate positions

  % Lower bound.
  lb = x0;
  lb(:,1:2) = lb(:,1:2) - 2*max(1,psfSigma(1));
  lb(:,3) = lb(:,3) - max(1,psfSigma(3));
  minPos = min(clusterPixels,[],1); % Bound by pixels comprising cluster
  lb = bsxfun(@max,lb,minPos);

  % Upper bound.
  ub = x0;
  ub(:,1:2) = ub(:,1:2) + 2*max(1,psfSigma(1));
  ub(:,3) = ub(:,3) + max(1,psfSigma(3));
  maxPos = max(clusterPixels,[],1); % Bound by pixels comprising cluster
  ub = bsxfun(@min,ub,maxPos);

  if fitAmp
    % Add amplitudes.
    x0 = [x0 amp];
    lb(:,end+1) = eps;
    ub(:,end+1) = inf;
  end

  if fitPsf
    % Add PSF
    x0 = [x0 psfSigma([1 3])];
    lb(:,end+1:end+2) = eps;
    ub(:,end+1:end+2) = 5*psfSigma([1 3]);
  end

  % Reshape.
  x0 = x0';
  x0 = x0(:);
  lb = lb';
  lb = lb(:);
  ub = ub';
  ub = ub(:);

end % function guessBounds
