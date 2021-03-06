function Vis(k_p, typ, varargin)
%VIS is used to visualize \bar{\bar{A}} or \bar{\bar{C}}.
% k_p is coherent vector.
% typ can be 'C' or 'A' which represents differnt visualization approach.
% 'C' plots each k_p by a dot, and 'A' plots each k_p by the corresponding
% covarianve matrix \bar{\bar{T}} = \bar{k}_p \cdot \bar{k}_p^t.
% Option: 'C_2D' = true, 'A_2D' = false, 'A_Subplot' = true,

    chk_pw()
	% Parse input parameter
	parse_ = inputParser;
	validationFcn_1_ = @(x) validateattributes(x,{'logical'},{});
	validationFcn_2_ = @(x) validateattributes(x,{'logical'},{});
    validationFcn_3_ = @(x) validateattributes(x,{'logical'},{});
    validationFcn_4_ = @(x) validateattributes(x,{'numeric'},{});
	addParameter(parse_,'C_2D',true, validationFcn_1_);
    addParameter(parse_,'A_2D',false ,validationFcn_2_);    
	addParameter(parse_,'A_Subplot',true, validationFcn_3_);
    addParameter(parse_,'T',[], validationFcn_4_);
	parse(parse_,varargin{:})
    if numel(parse_.Results.T)>0
        VisByT(parse_.Results.T, parse_.Results.A_Subplot)
        return 
    end
    %% Generate hemisphere.
	SP_NUM = 700;
	thetavec = linspace(0,pi/2,SP_NUM/2);
	phivec = linspace(0,2*pi,2*SP_NUM);
	[th, ph] = meshgrid(thetavec,phivec);
	[x_plain, y_plain] = meshgrid(linspace(-1,1,SP_NUM),linspace(-1,1,SP_NUM));
	radial = ones(size(th)); % should be your R(theta,phi) surface in general
	x = radial.*sin(th).*cos(ph);
	y = radial.*sin(th).*sin(ph);
	z = radial.*cos(th);
	
	%% Parameters
	[~, num_k_p] = size(k_p);
	S_a = 1/sqrt(2)*[1; 0; 1];
	S_b = 1/sqrt(2)*[1; 0; -1];
	S_c = 1/sqrt(2)*[0; 2; 0];
    sig = 1e-4*eye(2);
	if strcmp(typ, 'C')
		F = zeros(size(th));
		F_plain = zeros(size(x_plain));
	else
		alphabets = char(97:96+num_k_p).'; % Label for subplot, start from a to ...
		subplot_label = strcat({'('}, alphabets, {')'});		
	end
	
	%% Generate k'_p
	for qq = 1 : num_k_p
        k_p(:,qq) = k_p(:,qq)/norm(k_p(:,qq),2); % Normalize k_p
		% Judge if it is symmetry
		S = 1/sqrt(2)*[k_p(1,qq)+k_p(2,qq); sqrt(2)*k_p(3,qq); k_p(1,qq)-k_p(2,qq)];
		chi = 0.5*atand((conj(k_p(2,qq))*k_p(3,qq) + k_p(2,qq)*conj(k_p(3,qq)))/(abs(k_p(2,qq))^2 + abs(k_p(3,qq))^2));
		DS = dot(S, S_a)*S_a + dot(S, cosd(chi)*S_b+sind(chi)*S_c)*(cosd(chi)*S_b+sind(chi)*S_c);
		tau = acos(dot(S,DS)/norm(S)/norm(DS));
		symmetry = (tau <= 8/pi);
		if tau > 8/pi
			symmetry = 0;
			disp('asymmetry target')
		end
				% Caulculate the deorientation angle
		alpha = acosd(abs(k_p(1,qq)));
		beta = acosd(abs(k_p(2,qq))/sind(alpha));
		if ~isreal(beta)
			fprintf('beta is not real number, alpha = %f, beta = %f+%fi \n', alpha, real(beta), imag(beta) )
			beta = real(beta);
		end
		phi_2 = atan2d(imag(k_p(2,qq)), real(k_p(2,qq)));
		phi_3 = atan2d(imag(k_p(3,qq)), real(k_p(3,qq)));
		psi_ana = mod((2*(cosd(phi_2-phi_3)>=0)-1)/4*(2*beta - mod(2*beta, 180) ......
			+ mod(atand(tand(2*beta)*abs(cosd(phi_2-phi_3))), 180)), 90);
        if(k_p(3,qq) == 0)
            psi_ana = 0;
        end
		S_hh = (k_p(1,qq)+k_p(2,qq))/sqrt(2);
        S_vv = (k_p(1,qq)-k_p(2,qq))/sqrt(2);
        S_hv = k_p(3,qq)/sqrt(2);
        a = atand(abs(S_vv)/abs(S_hh));
        %b = 0.5*(atan2d(imag(S_vv),real(S_vv)-atan2d(imag(S_hh),real(S_hh));
        c = acosd(sqrt(2)*abs(S_hv)/norm([S_hh, sqrt(2)*S_hv, S_vv]));
        u = sind(c)*cosd(2*a);
        psi_ana = psi_ana+90*(u<0);
        %fprintf('Orientation angle: %f \n', psi_ana)
		%% Generate the pattern
		if symmetry
			k_pp = abs(k_p(:,qq)).*[1, cosd(2*psi_ana), sind(2*psi_ana)].';
		else
			R_T = [1, 0, 0; 0, cosd(2*psi_ana),-sind(2*psi_ana); 0, sind(2*psi_ana), cosd(2*psi_ana)];
			temp = R_T*k_p(:,qq);
			temp = real(2*temp(1)-1);
			k_pp = 1/(2+2*temp^2)*[(1-temp)*cosd(2*psi_ana), (1-temp)*sind(2*psi_ana), 1+temp].';
        end
				
		if strcmp(typ, 'C')
			F = F + reshape(mvnpdf([x(:) y(:)],k_pp(2:3).', sig), size(th));
			F_plain = F_plain + reshape(mvnpdf([x_plain(:) y_plain(:)],k_pp(2:3).', sig), size(x_plain));
		else
			% Visual. of \bar{A}_q
			A_q = k_p(:,qq)*k_p(:,qq)';
            mu = k_pp';
            
            if(det(A_q) < 0.00001)
                F_temp = reshape(mvnpdf([x(:) y(:)], k_pp(2:3).', sig), size(th));
                F_plain_temp = reshape(mvnpdf([x_plain(:) y_plain(:)], k_pp(2:3).', sig), size(x_plain));
            else 
                A_q_inv = inv(A_q);
                F_temp = 1/(pi^3*det(A_q))*exp(-(real(A_q_inv(1,1))*(z-mu(3)).^2 + real(A_q_inv(2,2))*(x-mu(1)).^2 + .......
                    real(A_q_inv(3,3))*(y-mu(2)).^2 + 2*real(A_q_inv(1,2))*(x-mu(1)).*(z-mu(3)) +......
                    2*real(A_q_inv(1,3))*(y-mu(2)).*(z-mu(3)) + 2*real(A_q_inv(2,3))*(x-mu(1)).*(y-mu(2))));
                F_plain_temp = 1/sqrt((2*pi)^2*det(A_q))*exp(-1/2*(A_q_inv(1,1)*(x_plain-mu(1)).^2 + ......
                    (A_q_inv(1,2)+A_q_inv(2,1))*(x_plain-mu(1)).*(y_plain-mu(2)) + A_q_inv(2,2)*(y_plain-mu(2)).^2));
            end
            
			F = ind2rgb(uint8((F_temp/max(max(F_temp)))*255),jet);
			F_plain = F_plain_temp/max(max(F_plain_temp));
			if parse_.Results.A_Subplot
				% We can plot a circular plot by using SURF
				% and view topdown
				subplot(2, 4, qq)
				surf(x,y,z,F,'EdgeColor','none')
				set(gca,'View',[0,90],'TickLength',[0,0],'YColor','none',......
					'XTickLabelMode','manual','GridColor','none')
				xlabel(subplot_label(qq),'Interpreter', 'latex','Fontsize',28)
				pbaspect([1 1 1])
			else
				% Plot each \bar{A} in different figure
				figure
				if parse_.Results.A_2D
					imagesc(x_plain(1,:), y_plain(:,1),-F_plain/max(max(F_plain)))
					xlabel('$|k''_{p2}| \cos (2 \psi_m) / \|\bar{k}_p\|_2$','Interpreter', 'latex')
					ylabel('$|k''_{p3}| \sin (2 \psi_m)/ \|\bar{k}_p\|_2 $','Interpreter', 'latex')
					grid on
					colormap gray
				else
					surf(x,y,z,F,'EdgeColor','none')
					view(135,30);
					xlabel('$|k''_{p2}| \cos (2 \psi_m) / \|\bar{k}_p\|_2$','Interpreter', 'latex')
					ylabel('$|k''_{p3}| \sin (2 \psi_m)/ \|\bar{k}_p\|_2 $','Interpreter', 'latex')
					zlabel('$|k''_{p1}| / \|\bar{k}_p\|_2 $','Interpreter', 'latex')
				end
			end
		end
	end
	if ~strcmp(typ, 'C') && parse_.Results.A_Subplot
		plot_para('Maximize',true,'Filename','SimAtom')
		movefile SimAtom.jpg output
	end

    if strcmp(typ, 'C') % Visual. of coherent target space 
		F_color = ind2rgb(uint8((F/max(max(F)))*255),jet);
		F_black = -(F/max(max(F)))*255;
		F_plain = F_plain/max(max(F_plain));
		if parse_.Results.C_2D
			figure
            imagesc(x_plain(1,:), y_plain(:,1),-F_plain)
            xlabel('$|k''_{p2}| \cos (2 \psi_m) / \|\bar{k}_p\|_2$','Interpreter', 'latex')
            ylabel('$|k''_{p3}| \sin (2 \psi_m)/ \|\bar{k}_p\|_2 $','Interpreter', 'latex')
            grid on
            colormap gray
		else 
			figure
			surf(x,y,z,F_black,'EdgeColor','none')
            colormap gray
			view(135,30);
			xlabel('$|k''_{p2}| \cos (2 \psi_m) / \|\bar{k}_p\|_2$','Interpreter', 'latex')
			ylabel('$|k''_{p3}| \sin (2 \psi_m)/ \|\bar{k}_p\|_2 $','Interpreter', 'latex')
			zlabel('$|k''_{p1}| / \|\bar{k}_p\|_2 $','Interpreter', 'latex')
            hold on 
            %% Generate mesh grid
            SP_NUM = 20;
            thetavec = linspace(0,pi/2,SP_NUM/2);
            phivec = linspace(0,2*pi,2*SP_NUM);
            [th, ph] = meshgrid(thetavec,phivec);
            R = ones(size(th)); % should be your R(theta,phi) surface in general
            x = R.*sin(th).*cos(ph);
            y = R.*sin(th).*sin(ph);
            z = R.*cos(th);			
            surf(x,y,z,'FaceColor','none','FaceAlpha',1);
            hold off
		end
		if 0
           	plot_para('Ratio',[2 2 1],'Maximize', true,'Filename', 'VisCo','Fontsize',32)
			movefile 'VisCo.jpg' output
		end
    end
	%% Display the sphere coordinate
	if 0
		figure
		surf(x,y,z,'FaceColor','w')
		view(135,30);
		xlabel('$|k''_{p2}| \cos (2 \psi_m) / \|\bar{k}_p\|_2$','Interpreter', 'latex')
		ylabel('$|k''_{p3}| \sin (2 \psi_m)/ \|\bar{k}_p\|_2 $','Interpreter', 'latex')
		zlabel('$|k''_{p1}| / \|\bar{k}_p\|_2 $','Interpreter', 'latex')
		plot_para('Ratio',[2 2 1],'Maximize', true,'Filename', 'VisSph','Fontsize',32)
	end
end
function VisByT(T, subp)
    %% Generate hemisphere.
	SP_NUM = 700;
	thetavec = linspace(0,pi/2,SP_NUM/2);
	phivec = linspace(0,2*pi,2*SP_NUM);
	[th, ph] = meshgrid(thetavec,phivec);
	[x_plain, y_plain] = meshgrid(linspace(-1,1,SP_NUM),linspace(-1,1,SP_NUM));
	radial = ones(size(th)); % should be your R(theta,phi) surface in general
	x = radial.*sin(th).*cos(ph);
	y = radial.*sin(th).*sin(ph);
	z = radial.*cos(th);
	
	%% Parameters
	[~,~, num_T] = size(T);
	S_a = 1/sqrt(2)*[1; 0; 1];
	S_b = 1/sqrt(2)*[1; 0; -1];
	S_c = 1/sqrt(2)*[0; 2; 0];
	alphabets = char(97:96+num_T).'; % Label for subplot, start from a to ...
	subplot_label = strcat({'('}, alphabets, {')'});
	
    for qq = 1 : num_T        
		T(:,:,qq) = T(:,:,qq)/trace(T(:,:,qq));
        A_q = T(:,:,qq);
		k_p = [sqrt(T(1,1,qq)); sqrt(T(2,2,qq))*exp(-1j*angle(T(1,2,qq))); ......
				sqrt(T(3,3,qq))*exp(-1j*angle(T(1,3,qq)))];
		A_q_inv = inv(T(:,:,qq));
		% Judge if it is symmetry
		S = 1/sqrt(2)*[k_p(1)+k_p(2); sqrt(2)*k_p(3); k_p(1)-k_p(2)];
		chi = 0.5*atand((conj(k_p(2))*k_p(3) + k_p(2)*conj(k_p(3)))/(abs(k_p(2))^2 + abs(k_p(3))^2));
		DS = dot(S, S_a)*S_a + dot(S, cosd(chi)*S_b+sind(chi)*S_c)*(cosd(chi)*S_b+sind(chi)*S_c);
		tau = acos(dot(S,DS)/norm(S)/norm(DS));
		symmetry = (tau <= 8/pi);
		if tau > 8/pi
			symmetry = 0;
			disp('asymmetry target')
		end
				% Caulculate the deorientation angle
		alpha = acosd(abs(k_p(1)));
		beta = acosd(abs(k_p(2))/sind(alpha));
		if ~isreal(beta)
			fprintf('beta is not real number, alpha = %f, beta = %f+%fi \n', alpha, real(beta), imag(beta) )
			beta = real(beta);
		end
		phi_2 = atan2d(imag(k_p(2)), real(k_p(2)));
		phi_3 = atan2d(imag(k_p(3)), real(k_p(3)));
		psi_ana = mod((2*(cosd(phi_2-phi_3)>=0)-1)/4*(2*beta - mod(2*beta, 180) ......
			+ mod(atand(tand(2*beta)*abs(cosd(phi_2-phi_3))), 180)), 90);
		S_hh = (k_p(1)+k_p(2))/sqrt(2);
        S_vv = (k_p(1)-k_p(2))/sqrt(2);
        S_hv = k_p(3)/sqrt(2);
        a = atan2d(abs(S_vv),abs(S_hh));
        c = acosd(sqrt(2)*abs(S_hv)/norm([S_hh, sqrt(2)*S_hv, S_vv]));
        u = sind(c)*cosd(2*a);
        psi_ana = psi_ana+90*(u<0);
		%% Generate the pattern
		if symmetry
			k_pp = abs(k_p).*[1, cosd(2*psi_ana), sind(2*psi_ana)].';
		else
			R_T = [1, 0, 0; 0, cosd(2*psi_ana),-sind(2*psi_ana); 0, sind(2*psi_ana), cosd(2*psi_ana)];
			temp = R_T*k_p;
			temp = real(2*temp(1)-1);
			k_pp = 1/(2+2*temp^2)*[(1-temp)*cosd(2*psi_ana), (1-temp)*sind(2*psi_ana), 1+temp].';
        end
        %mu = k_pp;
        mu = [0,0,1];
        F_temp = 1/(pi^3*det(A_q))*exp(-(real(A_q_inv(1,1))*(z-mu(3)).^2 + real(A_q_inv(2,2))*(x-mu(1)).^2 + .......
                    real(A_q_inv(3,3))*(y-mu(2)).^2 + 2*real(A_q_inv(1,2))*(x-mu(1)).*(z-mu(3)) +......
                    2*real(A_q_inv(1,3))*(y-mu(2)).*(z-mu(3)) + 2*real(A_q_inv(2,3))*(x-mu(1)).*(y-mu(2))));
        F = ind2rgb(uint8((F_temp/max(max(F_temp)))*255),jet);
        figure(999)
        % We can plot a circular plot by using SURF and view topdown
        num_temp = num_T + mode(num_T,2);
        subplot(2, num_temp/2, qq)
        surf(x,y,z,F,'EdgeColor','none')
        set(gca,'View',[0,90],'TickLength',[0,0],'YColor','none',......
            'XTickLabelMode','manual','GridColor','none')
        xlabel(subplot_label(qq),'Interpreter', 'latex','Fontsize',28)
        pbaspect([1 1 1])
    end
	plot_para('Maximize',true,'Filename', ['Atom_', int2str(num_T)])
	movefile(['Atom_', int2str(num_T), '.jpg'], 'output')
end