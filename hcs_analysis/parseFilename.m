function [row,col,field]=parseFilename(filename, mode)
% Parse image coordinates out of filename
% mode: 'hcs' or 'dv'

switch mode
  case 'hcs'
    pat = 'r([\d]+)c([\d]+)f([\d]+)';
  case 'dv'
    pat = '_([\d]{2,3})_(R3D|D3D)';
  otherwise
    error(['Unknown filename parsing mode: ' mode]);
end

s = regexp(filename, pat,'tokens');
if isempty(s)
  row = [];
  col = [];
  field = [];
  return;
end

switch mode
  case 'hcs'
    row = str2double(s{1}{1});
    col = str2double(s{1}{2});
    field = str2double(s{1}{3});
  case 'dv'
    row = 1;
    col = 1;
    field = str2double(s{1}{1});
end

