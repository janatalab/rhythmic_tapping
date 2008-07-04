function report = varTestN_summaryReport(report,p_vt)


reportIdx = 1;

for icol = 1:size(report.data,2)
  
    report.varTestN{reportIdx}.rows = [p_vt.rows{:}];
    report.varTestN{reportIdx}.cols = p_vt.cols{icol};
    report.varTestN{reportIdx}.data = ioiVarTestN(report.data(:, ...
						  icol),p_vt);
    
    reportIdx = reportIdx + 1;
end
