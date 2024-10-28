function reportSigVsSDS( ml, rhoSDS, dSig, hAxes )

axes(hAxes.ax1)

ymin = 1e-4;

hp=semilogy(hAxes.ax1, rhoSDS, max(dSig,ymin), 'r.' );
ylim(hAxes.ax1,[ymin 1])
title(hAxes.ax1, 'Signal vs SDS' )
xlabel(hAxes.ax1,'Rho (mm)')