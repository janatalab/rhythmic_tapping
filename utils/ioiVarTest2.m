function result = ioiVarTest2(ioiStruct,params)
%
%
% performs a vartestn on a series of ioi vectors, stored as a cell
% array of ioi info structs
%
% 27 Feb, 2007 S.T.

ioiMat = [];

if(length(ioiStruct) ~= 2)
  error('ioiStruct must be of length 2');
end


  
vector1 = ioiStruct{1}.ioi;  
vector1 = vector1(vector1 > params.lowerLim & vector1 < params.upperLim);

vector2 = ioiStruct{2}.ioi;
vector2 = vector2(vector2 > params.lowerLim & vector2 < params.upperLim);
 
[result.h,result.p,result.ci] = vartest2(vector1,vector2);
