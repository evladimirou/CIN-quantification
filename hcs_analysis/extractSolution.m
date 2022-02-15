function [clusterCands,clusterAmp,psfSigma]=extractSolution(solution,numCands)
  % solution: output from fitting.

  % Reshape solution in nx4.
  if nargout>2
    % Extract PSF sigma
    psfVals = 2;
  else
    psfVals = 0;
  end
  if nargout>1
    % Extract spot amps.
    vars = 4;
  else
    vars = 3;
  end
  solution = reshape(solution,vars+psfVals,numCands)';

  % Extract positions and amplitudes.
  clusterCands = solution(:,1:3);
  if nargout>1
    clusterAmp = solution(:,4);
  end
  if nargout>2
    psfSigma = solution(:,5:6);
  end
end
