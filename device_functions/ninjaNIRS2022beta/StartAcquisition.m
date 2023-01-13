function stat=StartAcquisition(sp,stat)

stat.rst_pca = false;
stat.rst_pcb = false;
stat.rst_clkdiv = false;
stat.rst_detb = false;
stat = updateStatReg(stat);
pause(0.6);
stat.run = true;
stat = updateStatReg(sp,stat);