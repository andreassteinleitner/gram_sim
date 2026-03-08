% MATLAB Skript: topics_generator.m
% Reads a logger-topics.txt, generates echo commands for the mavlink
% console and generates C-Code for the default logger configuration.

scriptPath = mfilename('fullpath');
[filepath, ~, ~] = fileparts(scriptPath);
logger_topicsDir = fullfile(filepath, '..', 'common', 'logger_topics');
while ~exist(logger_topicsDir, 'dir')
    disp('logger_topics directory not found.')
    disp('go to logger_topics folder')
    moduleBaseDir = fullfile(uigetdir);
end

inputFile = fullfile(logger_topicsDir, 'logger_topics.txt');
outputFile = fullfile(logger_topicsDir, 'echo_topics.txt');
defaultsOutputFile = fullfile(logger_topicsDir, 'default_topics.txt');

fid_in = fopen(inputFile, 'r');
if fid_in == -1
    error('Could not open input file: %s', inputFile);
end

fid_out = fopen(outputFile, 'w');
if fid_out == -1
    fclose(fid_in);
    error('Could not open output file: %s', outputFile);
end
fid_def_out = fopen(defaultsOutputFile, 'w');
if fid_def_out == -1
    fclose(fid_in);
    error('Could not open output file: %s', defaultsOutputFile);
end

% delete logger_topics.txt first
cmd = sprintf('rm "/fs/microsd/etc/logging/logger_topics.txt"');
fprintf(fid_out, '%s\n', cmd);

while ~feof(fid_in)
    line = strtrim(fgetl(fid_in));
    if isempty(line)
        continue;
    end    
    parts = strsplit(line, ' ');

    cmd = sprintf('echo "%s, %s %s" >> "/fs/microsd/etc/logging/logger_topics.txt"', parts{1}, parts{2}, parts{3});
    cmd_def = sprintf('\tadd_topic("%s", %s, %s);', parts{1}, parts{2}, parts{3});
    fprintf(fid_out, '%s\n', cmd);
    fprintf(fid_def_out, '%s\n', cmd_def);
end

fclose(fid_in);
fclose(fid_out);
fclose(fid_def_out);

disp(['Done! The results have been written to ', outputFile, ' and ', defaultsOutputFile, '!']);