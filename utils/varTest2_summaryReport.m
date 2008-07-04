function report = varTest2_summaryReport(report,p_vt)

reportIdx = 1;

for irow = 1:size(report.data,1)
  for icol = 1:size(report.data,2)
    
    for compRow = setdiff([1:size(report.data,1)],irow)
    
      report.varTest2{reportIdx}.rows = [p_vt.rows{irow} p_vt.rows{compRow}];
      report.varTest2{reportIdx}.cols = p_vt.cols{icol};
    
      report.varTest2{reportIdx}.data = ioiVarTest2(report.data([irow compRow],icol),p_vt);
      
      reportIdx = reportIdx + 1;
      
    end
    
  end
end
