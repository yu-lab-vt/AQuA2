function findKeyPress(f,event)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here
if strcmp(event.EventName,'KeyRelease')
    if strcmp(event.Key,'leftarrow')
        ui.mov.stepOne([],[],f,-1);
    elseif strcmp(event.Key,'rightarrow')
        ui.mov.stepOne([],[],f,1);
    end
end
end