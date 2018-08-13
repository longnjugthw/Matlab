function readPolsarData(obj)
    % READPOLSARDATA read polarimetric SAR data. 
    %
    % Syntax: READPOLSARDATA()
    % Other m-files required: none
    % Subfunctions: UAVSAR() and PALSAR()
    % MAT-files required: none
    %
    %------------- <<<<< >>>>>--------------
    % Author: K.S. Yang
    % email: fbookzone@gmail.com
    %------------- <<<<< >>>>>--------------
    disp('loading data...')
    switch obj.PLATFORM
        case 'ALOS PALSAR'
            palsar(obj);
        case 'UAVSAR'
            uavsar(obj);
        otherwise
            error('The platform is not support!')
    end
end
function palsar(obj)
	%% Check the image size is correct
    type([obj.INPUT_PATH '/config.txt'])
    %% Read ALOS PALSAR data.
    % 1/2 |S_{hh} + S_{vv}|^2
    fid = fopen([obj.INPUT_PATH '/' 'T11.bin'],'r','ieee-le'); 
    obj.T_11 = (single(fread(fid, obj.IMAGE_SIZE,'real*4')));
    % 1/2 |S_{hh} - S_{vv}|^2
    fid = fopen([obj.INPUT_PATH '/' 'T22.bin'],'r','ieee-le'); 
    obj.T_22 = (single(fread(fid, obj.IMAGE_SIZE,'real*4')));
    % 2|S_{hv}|^2
    fid = fopen([obj.INPUT_PATH '/' 'T33.bin'],'r','ieee-le'); 
    obj.T_33 = (single(fread(fid, obj.IMAGE_SIZE,'real*4')));
    % 1/2 (S_{hh}+S_{vv}) (S_{hh}-S_{vv})^*
    fid = fopen([obj.INPUT_PATH '/' 'T12_real.bin'],'r','ieee-le'); 
    obj.T_12 = (single(fread(fid, obj.IMAGE_SIZE,'real*4')));
    fid = fopen([obj.INPUT_PATH '/' 'T12_imag.bin'],'r','ieee-le'); 
    obj.T_12 = obj.T_12 + 1j*(single(fread(fid, obj.IMAGE_SIZE,'real*4')));
    % (S_{hh}+S_{vv}) S_{hv} 
    fid = fopen([obj.INPUT_PATH '/' 'T13_real.bin'],'r','ieee-le'); 
    obj.T_13 = (single(fread(fid, obj.IMAGE_SIZE,'real*4')));
    fid = fopen([obj.INPUT_PATH '/' 'T13_imag.bin'],'r','ieee-le'); 
    obj.T_13 = obj.T_13 + 1j*(single(fread(fid, obj.IMAGE_SIZE,'real*4')));
    % (S_{hh}-S_{vv}) S_{hv} 
    fid = fopen([obj.INPUT_PATH '/' 'T23_real.bin'],'r','ieee-le'); 
    obj.T_23 = (single(fread(fid, obj.IMAGE_SIZE,'real*4')));
    fid = fopen([obj.INPUT_PATH '/' 'T23_imag.bin'],'r','ieee-le'); 
    obj.T_23 = obj.T_23 + 1j*(single(fread(fid, obj.IMAGE_SIZE,'real*4')));
	
	%% Convert coherency matrix to covariance matrix
    obj.coh2cov()
end
function uavsar(obj)
    % Read UAVSAR data.
end