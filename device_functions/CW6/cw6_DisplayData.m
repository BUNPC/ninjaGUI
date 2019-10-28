function cw6_DisplayData(app)

if ~isfield(app.devinfo,'nRecords')
    return;
end

%%%%%%%%%%%%%%%%%%
% DISPLAY the data


tstep = 1 / app.devinfo.recordRate;

% A.O. check if cla is needed or not
cla(app.axisPlotData);

idxLambda = app.devinfo.displayLambda;

if ~app.devinfo.DisplayAux
    % DISPLAY REAL DATA
    firstR = max(app.devinfo.nRecords-round(app.devinfo.DisplayWindow/tstep),1);
    if isfield( app.devinfo, 'plotLst1' ) & app.devinfo.nRecords>0
        %        lst = find(app.devinfo.SD.MeasListAct(app.devinfo.plotLst).*app.devinfo.MeasListOn(app.devinfo.plotLst)==1);
        lstw1 = find(app.devinfo.SD.MeasListAct(app.devinfo.plotLst1)==1);
        lstw2 = find(app.devinfo.SD.MeasListAct(app.devinfo.plotLst2)==1);
        lst = [lstw1;lstw2];
        if ~isempty(lst) & idxLambda>0
            lst2 = firstR:app.devinfo.nRecords;
            lst2sub = 1:length(lst2);%find(app.devinfo.data( app.devinfo.plotLst(lst(ii)), lst2)>60);
            
            data = app.devinfo.data(:,lst2(lst2sub));
            
            datastream=[app.devinfo.time(1,lst2(lst2sub));data([1,17],:)];
            app.LSLstreamer.outlet.push_chunk(datastream);
            
            %streaming commands
            fs=app.devinfo.recordRate;                        
            
            if length(lst2)>fs
                indi=lst2(end-fs:end-1);
            else
                indi=lst2(lst2sub);
            end
            data1 = app.devinfo.data(:,indi);
            time=app.devinfo.time(1,indi);
            auxi=app.devinfo.dataAux(:,indi);
            s=app.devinfo.stimMark(:,indi);
                                    
            datastream=[data1;auxi;s];
            app.LSLstreamer.outlet.push_chunk(datastream,time);
            
            %data = cw6info.data(:,lst2(lst2sub));
            
            if app.devinfo.DisplayHbX==1
                %                e = [ 0.9569 4.9326; 2.3214 1.7917] * 1e2;  % /mm
                %                einv = inv( e'*e )*e';
                einv = app.devinfo.SD.extCoefInv;
                
                for ii=1:length(lstw1)
                    idx1 = app.devinfo.plotLst1(lstw1(ii));
                    idx2 = find(app.devinfo.SD.MeasList(idx1,1)==app.devinfo.SD.MeasList(:,1) & app.devinfo.SD.MeasList(idx1,2)==app.devinfo.SD.MeasList(:,2) & app.devinfo.SD.MeasList(:,4)==2 );
                    dod1 = (data( idx1, :) - mean(data( idx1, :),2))*(-0.115);
                    dod2 = (data( idx2, :) - mean(data( idx2, :),2))*(-0.115);
                    dataTmp = (einv * [dod1; dod2]);
                    data(idx1,:) = dataTmp(2,:);
                    data(idx2,:) = dataTmp(1,:);
                end
            end
            
            cla
            hold on
            if app.devinfo.DisplayNormalized % plot dOD
                if bitand(idxLambda,1)>0
                    for ii=length(lstw1):-1:1
                        if app.devinfo.DisplayHbX==0
                            h=plot(app.axisPlotData,...
                                app.devinfo.time(lst2(lst2sub)),...
                                (data( app.devinfo.plotLst1(lstw1(ii)), :) -...
                                mean(data( app.devinfo.plotLst1(lstw1(ii)), :),2))*(-0.115) ); % convert to delta OD from dB
                        else
                            h=plot(app.axisPlotData,app.devinfo.time(lst2(lst2sub)), data( app.devinfo.plotLst1(lstw1(ii)), :) );
                        end
                        set(h,'linestyle','-.');% v1.4 Change line property
                        set(h,'color',app.devinfo.color(lstw1(ii),:));
                    end
                end
                if bitand(idxLambda,2)>0
                    for ii=length(lstw2):-1:1
                        if app.devinfo.DisplayHbX==0
                            h=plot(app.axisPlotData,app.devinfo.time(lst2(lst2sub)),...
                                (data( app.devinfo.plotLst2(lstw2(ii)), :) -...
                                mean(data( app.devinfo.plotLst2(lstw2(ii)), :),2))*(-0.115) ); % convert to delta OD from dB
                        else
                            h=plot(app.axisPlotData,app.devinfo.time(lst2(lst2sub)), data( app.devinfo.plotLst2(lstw2(ii)), :) );
                        end
                        set(h,'color',app.devinfo.color(lstw2(ii),:));
                    end
                end
            else % plot dB
                if bitand(idxLambda,1)>0
                    for ii=length(lstw1):-1:1
                        h=plot(app.axisPlotData,...
                            app.devinfo.time(lst2(lst2sub)),...
                            data( app.devinfo.plotLst1(lstw1(ii)), :) );
                        set(h,'color',app.devinfo.color(lstw1(ii),:));
                        set(h,'linestyle','-.');% v1.4 Change line property
                    end
                end
                if bitand(idxLambda,2)>0
                    for ii=length(lstw2):-1:1
                        h=plot(app.axisPlotData,...
                            app.devinfo.time(lst2(lst2sub)),...
                            data( app.devinfo.plotLst2(lstw2(ii)), :) );
                        set(h,'color',app.devinfo.color(lstw2(ii),:));
                    end
                end
            end
            hold off
            %        h=get(gca,'children');
            %        for idx=1:length(h)
            %            set(h(idx),'color',app.devinfo.color(lst(idx),:));
            %        end
            %            xlim( app.devinfo.time([firstR app.devinfo.nRecords]) )
            if app.devinfo.autoscale==0 & ~(app.devinfo.DisplayNormalized==1 & app.devinfo.Yrange(1)>0) & app.devinfo.DisplayHbX==0
                ylim( app.axisPlotData,app.devinfo.Yrange );
                ylabel( app.axisPlotData,'dB' )
            elseif app.devinfo.autoscale==0 & app.devinfo.DisplayNormalized==1 & app.devinfo.DisplayHbX==0
                ylim( app.axisPlotData,app.devinfo.YrangeDOD );
                ylabel( app.axisPlotData,'Optical Density' )
            elseif app.devinfo.autoscale==0 & app.devinfo.DisplayHbX==1
                ylim( app.axisPlotData,app.devinfo.YrangeHbX );
                ylabel( app.axisPlotData,'Hemoglobin (Molar mm)' )
            else
                ylim('auto')
                if ~(app.devinfo.DisplayNormalized==1 & app.devinfo.Yrange(1)>0) & app.devinfo.DisplayHbX==0
                    ylabel( app.axisPlotData,'dB' )
                elseif app.devinfo.DisplayNormalized==1 & app.devinfo.DisplayHbX==0
                    ylabel( app.axisPlotData,'Optical Density' )
                elseif app.devinfo.DisplayHbX==1
                    ylabel( app.axisPlotData,'Hemoglobin (Molar mm)' )
                end
            end
        else
            cla(app.axisPlotData); %this use to be clf but that crashed
        end
    end
end

lstA = find(app.devinfo.DisplayAuxList==1);
if app.devinfo.nRecords>0
    firstR = max(app.devinfo.nRecords-round(app.devinfo.DisplayWindow/tstep),1);
    lst2 = firstR:app.devinfo.nRecords;
    
    % DISPLAY AUX DATA
    if ~isempty(lstA)
        
        if app.devinfo.DisplayAux
            plot( app.axisPlotData, app.devinfo.time(lst2), app.devinfo.dataAux(lstA,lst2)','--' );
        else
            hold(app.axisPlotData,'on');
            yrange = ylim(app.axisPlotData);
            plot( app.axisPlotData, app.devinfo.time(lst2), (yrange(2)-yrange(1))*app.devinfo.dataAux(lstA,lst2)'/5+yrange(1), '--' );
            hold(app.axisPlotData,'off');
        end
    end
    
    % DISPLAY Stim Marks
    hold(app.axisPlotData,'on');
    yrange = ylim(app.axisPlotData);
    plot( app.axisPlotData, app.devinfo.time(lst2), (yrange(2)-yrange(1))*app.devinfo.stimMark(lst2)+yrange(1), 'm-' );
    hold(app.axisPlotData,'off');
end


xlim( app.axisPlotData,app.devinfo.time([firstR app.devinfo.nRecords]) )
set(app.axisPlotData,'ygrid','on')

