function cw6_SetupSimulation(app)

nml = size(app.devinfo.SD.MeasList,1);
nsrcs = app.devinfo.SD.nSrcs;
ndets = app.devinfo.SD.nDets;


app.cw6simul.srcCC = max(1 + 0.4*randn(1,nsrcs),0.01);
app.cw6simul.detCC = max(1 + 0.4*randn(1,ndets),0.01);


