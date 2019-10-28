tic;
t=[];
x=[];
tspan=10;
while true
    
    tcur=toc;
    t=[t,tcur];
    
    a=randn(1,1);
    x=[x,a];
    plot(t,x)
    xlim([t(end)-10,t(end)])
    drawnow
    pause(0.1)
end