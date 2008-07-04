function result = ioiVarTestN(ioiStruct,params)
%
%
% performs a vartestn on a series of ioi vectors, stored as a cell
% array of ioi info structs
%
% 27 Feb, 2007 S.T.

ioiMat = [];

for idx = 1: length(ioiStruct(:))
  
  thisIOIVector = ioiStruct{idx}.ioi;
  
  thisIOIVector = thisIOIVector(thisIOIVector > params.lowerLim & ...
				thisIOIVector < params.upperLim);
  
  %dealing with different sizes of ioi vectors here
  %fill the matrix with NaNs if the new IOI vector is longer 
  if(~isempty(ioiMat) & (length(thisIOIVector) > size(ioiMat,1)) )
    fillerMat = ones(length(thisIOIVector)-size(ioiMat,1),size(ioiMat,2))*NaN;
  else
    fillerMat = [];
  end
  
  %fill the ioi vectors with NaNs if it's shorter than the matrix
  if(length(thisIOIVector) < size(ioiMat,1))
    fillerVec = ones(size(ioiMat,1) - length(thisIOIVector),1);
  else
    fillerVec = [];
  end
  
  %add the ioivector to the ioi matrix
  ioiMat = [ [ioiMat ; fillerMat] [thisIOIVector ; fillerVec] ];
  
end

[result.p,result.stats] = vartestn(ioiMat,[],'off');

