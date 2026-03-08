function copyCodeGenFilesV3(destFolder,sourceFolder)

% make code generation folder
[~,~,~] = mkdir(destFolder);

% find main ert_rtw relative path
ert_rtw_path = fullfile(sourceFolder,dir(fullfile(sourceFolder,['*','ert_rtw','*'])).name);

% find relative paths to submodule
slprj_path = fullfile(sourceFolder,'slprj','ert');
submodul_dir = dir(slprj_path); % get the slprj/ert/ folder contents
submodul_folders = submodul_dir([submodul_dir(:).isdir]==1); % remove all files (isdir property is 0)
submodul_folders = submodul_folders(~ismember({submodul_folders(:).name},{'.','..'})); % remove '.' and '..'

% add ert_rtw relative path to cell
srcfolders = {fullfile(ert_rtw_path)};
% add relative paths to submodules
for i=1:length(submodul_folders)
    srcfolders{i+1} = fullfile(slprj_path,submodul_folders(i).name);
end





for k=1:length(srcfolders)
    % Testing Copying with Renaming
%     inputFiles = dir( fullfile(srcfolders{k},'*.c') );
%     inputFiles_h = dir( fullfile(srcfolders{k},'*.h') );
%     size_inputFiles = length(inputFiles);
%     size_inputFiles_h = length(inputFiles_h);
%     for m = 1:size_inputFiles_h
%         inputFiles(size_inputFiles+m) = inputFiles_h(m);
%     end
%     fileNames = { inputFiles.name };
%     for n = 1 : length(inputFiles )
%       thisFileName = fileNames{n};
%       % Prepare the input filename.
%       inputFullFileName = fullfile(pwd, srcfolders{k},thisFileName);
%       % Prepare the output filename. 
%       outputBaseFileName = append('gencode_', thisFileName);
%       outputFullFileName = fullfile(pwd, destFolder, outputBaseFileName);
%       % Do the copying and renaming all at once.
%       copyfile(inputFullFileName, outputFullFileName);
%     end
    
    [~,~,~] = copyfile(fullfile(srcfolders{k},'*.c'), destFolder);
    [~,~,~] = copyfile(fullfile(srcfolders{k},'*.h'), destFolder);
end

delete(fullfile(destFolder, 'ert_main.c'));

%give unique identifier
% gen_code_files = dir(destFolder);
% gen_code_files = gen_code_files([gen_code_files(:).isdir]==0); % remove folders
% 
% for id = 1:length(gen_code_files)
%     % Get the file name 
%     [~, f,ext] = fileparts(gen_code_files(id).name);
%     rename = append('gencode_',f,ext); 
%     movefile(fullfile(destFolder,gen_code_files(id).name), fullfile(destFolder,rename)); 
% end

end


