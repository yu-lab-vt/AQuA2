function [] = checkHasSeed(Map,pix)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

hasSeed = false;
if ~isempty(find(Map(pix)),1)
    return;
end

[x_dir,y_dir,z_dir,t_dir] = se.dirGenerate(80); 
[]



end