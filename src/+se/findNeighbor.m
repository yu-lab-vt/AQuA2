function [bg1,bg2,nv1,nv2] = findNeighbor(curve,t0,t1,T,thr,curveSmo)
    nv1 = []; nv2 = [];
    dur = t1-t0+1;
    tLeft = max(t0-dur,1):(t0-1);
    tRight = (t1+1):min(t1+dur,T);
    bg1 = curve(tLeft);
    bg2 = curve(tRight);
    if(exist('thr','var'))
        nv1 = curve(tLeft(curveSmo(tLeft)>thr));
        nv2 = curve(tRight(curveSmo(tRight)>thr));
        bg1 = curve(tLeft(curveSmo(tLeft)<=thr));
        bg2 = curve(tRight(curveSmo(tRight)<=thr));
    end
end