function params = paramsTappingStats(varargin)

fields = {'leftHandMidiNote','rightHandMidiNote','IOIScaleFactor','left_IOIScaleFactor','right_IOIScaleFactor','ioiHistBinLim','ioiHistBinSize','ioiMinThresh'};

params = mkstruct(fields,varargin);
