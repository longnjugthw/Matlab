function Plotsetting_GOM2(Clim, sub_map, varargin)
    parse_ = inputParser;
	validationFcn_1_ = @(x) validateattributes(x,{'numeric'},{});
	addParameter(parse_,'Colorbar_unit',[],validationFcn_1_);
	parse(parse_,varargin{:})
    
    set(gca,'Ydir','normal','Clim',Clim)
    % Gulf of Mexico 2
    if sub_map == 0
        set(gca,'XTick',0:5000:36000, 'Xticklabel',cellstr(int2str((0:5000*7:36000*7)'/1000))')
        set(gca,'YTick',0:600:3300, 'Yticklabel',cellstr(int2str((0:600*5:3300*5)'/1000))')
    else
        set(gca,'XTick',1:1000:8000, 'Xticklabel',cellstr(int2str((0:1000*7:8000*7)'/1000))')
        set(gca,'YTick',1:600:3300, 'Yticklabel',cellstr(int2str((0:600*5:3300*5)'/1000))')
    end
    colormap jet; colorbar
    xlabel('Azimuth (km)', 'Interpreter', 'latex')
    ylabel('Range (km)', 'Interpreter', 'latex')
    if parse_.Results.Colorbar_unit
        title(colorbar,'(dB)','Position', parse_.Results.Colorbar_unit)
    end
end