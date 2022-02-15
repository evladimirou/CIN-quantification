function [solution,resnorm,residuals,jac]=fitNGaussiansFitFun(x0,lb,ub,img,pixels,bgAmp,psfSigma,psfAmp)

if nargin<7
  psfSigma = [];
  jac = 'off';
else
  jac = 'on';
end
if nargin<8
  psfAmp = [];
end

f = @fitNGaussians3D;

% Set optimization options.
options = optimset('Jacobian',jac,'Display','off','Tolfun',1e-4,'TolX',1e-4);

if isempty(psfSigma) && isempty(psfAmp)
  [solution,resnorm,residuals,exitFlag] = ...
  lsqnonlin(f,x0,lb,ub,options,img,pixels,bgAmp,[],[]);
elseif isempty(psfAmp)
  [solution,resnorm,residuals,exitFlag,~,~,jac] = ...
  lsqnonlin(f,x0,lb,ub,options,img,pixels,bgAmp,psfSigma,[]);
else
  [solution,resnorm,residuals,exitFlag,~,~,jac] = ...
  lsqnonlin(f,x0,lb,ub,options,img,pixels,bgAmp,psfSigma,psfAmp);
end

switch exitFlag
    case 0
        warning('fitNGaussiansFitFun: Number of iterations exceeded options.MaxIter or number of function evaluations exceeded options.MaxFunEvals.');
    case -2
        warning('fitNGaussiansFitFun: Problem is infeasible: the bounds lb and ub are inconsistent.');
    case -4
        warning('fitNGaussiansFitFun: Line search could not sufficiently decrease the residual along the current search direction.');
end
