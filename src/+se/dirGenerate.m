function [x_dir,y_dir,z_dir,t_dir] = dirGenerate(conn)
    if(conn==6)
        x_dir = [-1;1;0;0;0;0];
        y_dir = [0;0;-1;1;0;0];
        z_dir = [0;0;0;0;-1;1];
        t_dir = [];
    elseif(conn==26)
        x_dir = zeros(26,1);
        y_dir = zeros(26,1);
        z_dir = zeros(26,1);
        t_dir = [];
        cnt = 1;
        
        for x = -1:1
            for y = -1:1
                for z = -1:1
                    if x==0 && y==0 && z==0
                        continue;
                    else
                        x_dir(cnt) = x;
                        y_dir(cnt) = y;
                        z_dir(cnt) = z;
                        cnt = cnt + 1;
                    end
                end
            end
        end
        
    elseif(conn==80)
        x_dir = zeros(80,1);
        y_dir = zeros(80,1);
        z_dir = zeros(80,1);
        t_dir = zeros(80,1);
        cnt = 1;
        
        for x = -1:1
            for y = -1:1
                for z = -1:1
                    for t = -1:1
                        if x==0 && y==0 && z==0 && t==0
                            continue;
                        else
                            x_dir(cnt) = x;
                            y_dir(cnt) = y;
                            z_dir(cnt) = z;
                            t_dir(cnt) = t;
                            cnt = cnt + 1;
                        end
                    end
                end
            end
        end
    end

end