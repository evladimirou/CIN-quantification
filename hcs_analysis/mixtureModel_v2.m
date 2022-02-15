function spots=mixtureModel_v2(img, cands, bgAmp, verbose)

if nargin<4
  verbose = 0;
end

psfSigma0 = [2 2 2];
clusterSep = psfSigma0(1); % Distance criterion for defining separate clusters
fitfun = @fitNGaussiansFitFun;

% For each spot fit a first Gaussian to estimate PSF sigma.
nSpots = size(cands,1);
spots = zeros(nSpots,6);
if verbose
  fprintf('\nFitting PSF sigma\n');
end
for i=1:nSpots
  % Extract spot data.
  spot = cands(i,:);
  spotPix = getClusterPixels(img, spot, clusterSep);
  spotPix1D = sub2ind(size(img), spotPix(:,1), spotPix(:,2), spotPix(:,3));
  spotImg = img(spotPix1D);
  spot1D = sub2ind(size(img), spot(1), spot(2), spot(3));
  spotAmp = img(spot1D);

  % Fit Gaussian.
  [x0,lb,ub] = guessBounds(spot,spotAmp,spotPix,bgAmp,psfSigma0,'fitamp','fitpsf');

  [solution, resnorm] = fitfun(x0,lb,ub,spotImg,spotPix,bgAmp);
  [spot,spotAmp,spotPsf] = extractSolution(solution,1);
  spots(i,:) = [spot spotAmp spotPsf];
end

% Estimate PSF sigma:
psfSigma = trimmean(spots(:,5:6),50);
psfSigma = psfSigma([1 1 2]);
if verbose>1
  fprintf('PSF sigma: %s\n',num2str(psfSigma));
end

% Refit with fixed PSF sigma.
if verbose
  fprintf('Fitting PSF amplitude\n');
end
spots = zeros(nSpots,4);
for i=1:nSpots
  % Extract spot data.
  spot = cands(i,:);
  spotPix = getClusterPixels(img, spot, clusterSep);
  spotPix1D = sub2ind(size(img), spotPix(:,1), spotPix(:,2), spotPix(:,3));
  spotImg = img(spotPix1D);
  spot1D = sub2ind(size(img), spot(1), spot(2), spot(3));
  spotAmp = img(spot1D);

  % Fit Gaussian.
  [x0,lb,ub] = guessBounds(spot,spotAmp,spotPix,bgAmp,psfSigma,'fitamp');

  [solution, resnorm] = fitfun(x0,lb,ub,spotImg,spotPix,bgAmp, psfSigma);
  [spot,spotAmp] = extractSolution(solution,1);
  spots(i,:) = [spot spotAmp];
end

% Estimate spot amplitude.
cands = spots;
if nSpots>5
  warning('off','stats:gmdistribution:FailedToConverge');
  gmm = {};
  for k=1:4
    gmm{k} = fitgmdist(spots(:,4), k, 'Regularization', 0.0001, 'Options',statset('MaxIter',500));
  end
  warning('on','stats:gmdistribution:FailedToConverge');

  converged = cellfun(@(x) x.Converged, gmm);
  bic = cellfun(@(x) x.BIC, gmm);
  bic(~converged) = inf;
  [~,idx] = min(bic);
  
  if verbose>1
    fprintf('GMM components: %d\n', idx)
  end

  [~,map]=sort(gmm{idx}.mu);
  cidx = cluster(gmm{idx}, spots(:,4));
  cidx = map(cidx); % into increasing order
  for i=1:max(cidx)
    spots = [spots; cands(cidx>1, :)];
    cidx = cidx - 1;
  end

end