function stat = ResetCounters(s,stat)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
s.flush();
stat.rst_pca = true;
stat.rst_pcb = true;
stat.rst_clkdiv = true;
stat.rst_detb = true;
stat = updateStatReg(stat);
end