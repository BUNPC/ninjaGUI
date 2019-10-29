%$Release 4.0
% Copyright (c) Copyright 2004 - 2006 - The General Hospital Corporation and
% President and Fellows of Harvard University.
%
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% *       Redistributions of source code must retain the above copyright
% notice, this list of conditions and the following disclaimer.
% *       Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution.
% *       Neither the name of The General Hospital Corporation and Harvard
% University nor the names of its contributors may be used to endorse or
% promote products derived from this software without specific prior written
% permission.
%
% The Software has been designed for research purposes only and has not been
% reviewed or approved by the Food and Drug Administration or by any other
% agency.  YOU ACKNOWLEDGE AND AGREE THAT CLINICAL APPLICATIONS ARE NEITHER
% RECOMMENDED NOR ADVISED.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.


% --------------------------------------------------------------------
function cw6_plotAxesSDG(app)
%This function plots the prove geometry
%Command line call:
%plotAxes_SDG(guidata(gcbo),bool);
%
%Flags
%   newFigure- plot in new window








%axes(app.axesSDG);
%cla
axis(app.axesSDG, [app.devinfo.SD.xmin app.devinfo.SD.xmax app.devinfo.SD.ymin app.devinfo.SD.ymax]);
axis(app.axesSDG, 'image')
set(app.axesSDG,'xticklabel','')
set(app.axesSDG,'yticklabel','')
set(app.axesSDG,'ygrid','off')
ylabel(app.axesSDG,'')

%nRec = max(app.devinfo.nRecords,1);
%nRec = app.devinfo.nRecords;
if app.devinfo.nRecords>20
    nRec = [-20:0]+app.devinfo.nRecords;
else
    nRec = [1:2];
end

SD = app.devinfo.SD;
lst=find(SD.MeasList(:,1)>0);
ml=SD.MeasList(lst,:);
lstML = find(ml(:,4)==1); %app.devinfo.displayLambda);

% SIGNAL LEVEL
% if app.devinfo.SDGdisplayLevel
%     for ii=1:length(lstML) %size(ml,1)
%         h = line( [SD.SrcPos(ml(lstML(ii),1),1) SD.DetPos(ml(lstML(ii),2),1)], ...
%             [SD.SrcPos(ml(lstML(ii),1),2) SD.DetPos(ml(lstML(ii),2),2)] );
%         slevel = mean(app.devinfo.data(lstML(ii),nRec),2);
%         if slevel < app.devinfo.signalMinThresh
%             set(h,'color',[.6 .6 1]);
%             set(h,'linewidth',6);
%             set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
%         elseif slevel > app.devinfo.signalMaxThresh
%             set(h,'color',[1 0.2 0.2]);
%             set(h,'linewidth',6);
%             set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
%         else
%             set(h,'color',[1 1 1]*0.9);
%             set(h,'linewidth',4);
%             set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
%         end
%     end
% else
%     for ii=1:length(lstML) %size(ml,1)
%         h = line( [SD.SrcPos(ml(lstML(ii),1),1) SD.DetPos(ml(lstML(ii),2),1)], ...
%             [SD.SrcPos(ml(lstML(ii),1),2) SD.DetPos(ml(lstML(ii),2),2)] );
%
%         set(h,'color',[1 1 1]*0.9);
%         set(h,'linewidth',4);
%         set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
%     end
% end

% NOISE LEVEL
try % I put this in because of the error I think was caused by a new data display update
    % before the old data display update finished. The new one would delete
    % the axes. And thus when we get back to the old one, the objects are
    % deleted and we get and error with the handles
    
    if 1
        cmjet = gray(64);
        for ii=1:length(lstML) %size(ml,1)
            h = line( app.axesSDG,[SD.SrcPos(ml(lstML(ii),1),1) SD.DetPos(ml(lstML(ii),2),1)], ...
                [SD.SrcPos(ml(lstML(ii),1),2) SD.DetPos(ml(lstML(ii),2),2)] );
            %        snrlevel = std(diff(app.devinfo.data(lstML(ii),nRec),1,2),[],2) * .115; % convert from dB to delta OD
            % consider 2.3 / 20
            snrlevel = std(app.devinfo.data(lstML(ii),nRec),[],2) * .115; % convert from dB to delta OD
            % consider 2.3 / 20
            slevel = mean(app.devinfo.data(lstML(ii),nRec),2);
            if app.devinfo.SDGdisplayLevel==1
                if slevel < app.devinfo.signalMinThresh
                    set(h,'color',[.6 .6 1]);
                    set(h,'linewidth',6);
                    set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
                elseif slevel > app.devinfo.signalMaxThresh
                    set(h,'color',[1 0.2 0.2]);
                    set(h,'linewidth',6);
                    set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
                elseif snrlevel > app.devinfo.stdThresh
                    set(h,'color',[1 .9 0.2]);
                    set(h,'linewidth',6);
                    set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
                else
                    set(h,'color',[1 1 1]*0.9);
                    set(h,'linewidth',4);
                    set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
                end
            elseif app.devinfo.SDGdisplayLevel==2
                if slevel>app.devinfo.signalMinThresh & slevel<app.devinfo.signalMaxThresh
                    set(h,'color',cmjet( ceil(63*(slevel-app.devinfo.signalMinThresh+eps)/(app.devinfo.signalMaxThresh-app.devinfo.signalMinThresh)), :) )
                    set(h,'linewidth',4);
                elseif slevel>app.devinfo.signalMaxThresh
                    set(h,'color',[1 0 0]);
                    set(h,'linewidth',6);
                else
                    set(h,'color',[1 1 0]);
                    set(h,'linewidth',6);
                end
            else
                set(h,'color',[1 1 1]*0.9);
                set(h,'linewidth',4);
                set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
            end
            %         if snrlevel > 0.1
            %             set(h,'color',[1 0.2 0.2]);
            %             set(h,'linewidth',6);
            %             set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
            %         else
            %             set(h,'color',[1 1 1]*0.9);
            %             set(h,'linewidth',4);
            %             set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
            %         end
        end
    end
    
    
    % ADD SOURCE AND DETECTOR LABELS
    for idx=1:SD.nSrcs
        if ~isempty(find(SD.MeasList(:,1)==idx))
            h = text( app.axesSDG,SD.SrcPos(idx,1), SD.SrcPos(idx,2), sprintf('%c', 64+idx), 'fontweight','bold' );
            set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
        end
    end
    if 0
        for idx=1:SD.nDets
            if ~isempty(find(SD.MeasList(:,2)==idx))
                h = text(app.axesSDG, SD.DetPos(idx,1), SD.DetPos(idx,2), sprintf('%d', idx), 'fontweight','bold' );
                set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
            end
        end
    else
        for idx=1:SD.nDets
            lst = find(SD.MeasList(:,2)==idx);
            if ~isempty(lst)
                slevel = sum(10.^(mean(app.devinfo.data(lst,nRec),2)/20),1);
                if app.devinfo.detector_Saturated(idx)==1
                    h = text(app.axesSDG, SD.DetPos(idx,1), SD.DetPos(idx,2), sprintf('%d', idx), 'fontweight','bold','color','k','backgroundcolor','r' );
                elseif slevel > app.devinfo.signalDetMaxThresh
                    h = text(app.axesSDG, SD.DetPos(idx,1), SD.DetPos(idx,2), sprintf('%d', idx), 'fontweight','bold','color','k','edgecolor','r', 'linewidth', 2 );
                else
                    h = text( app.axesSDG,SD.DetPos(idx,1), SD.DetPos(idx,2), sprintf('%d', idx), 'fontweight','bold','color','k' );
                end
                set(h,'ButtonDownFcn',get(app.axesSDG,'ButtonDownFcn'));
            end
        end
    end
    
    
    % DRAW PLOT LINES
    % THESE LINES HAVE TO BE THE LAST
    % ITEMS ADDED TO THE AXES
    % FOR CHANNEL TOGGLING TO WORK WITH
    % cw6_sdgToggleLines()
    if isfield( app.devinfo, 'plot' )
        if ~isempty(app.devinfo.plot)
            if app.devinfo.plot(1,1)~=0
                app.devinfo.color(end:size(app.devinfo.plot,1),:)=0;
                for idx=size(app.devinfo.plot,1):-1:1
                    h = line( app.axesSDG,[SD.SrcPos(app.devinfo.plot(idx,1),1) SD.DetPos(app.devinfo.plot(idx,2),1)], ...
                        [SD.SrcPos(app.devinfo.plot(idx,1),2) SD.DetPos(app.devinfo.plot(idx,2),2)] );
                    set(h,'color',app.devinfo.color(idx,:));
                    set(h,'ButtonDownFcn',sprintf('app.funcSet.dev_sdgToggleLines(gcbo,[%d],guidata(gcbo))',idx));
                    set(h,'linewidth',2);
                    if isfield(app.devinfo,'plotLst1') && ~app.devinfo.SD.MeasListAct(app.devinfo.plotLst1(idx))
                        set(h,'linewidth',2);
                        set(h,'linestyle','--');
                    end
                    
                    
                end
            end
        end
    end
    
catch
end

