function plot_ioiDist(ts,params)
%
%
% plots an event that has midi tapping stats data (ioi dist)

bar(ts.ioiDistBinCenters,ts.ioiDist);
