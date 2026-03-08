function module_name = getCurrentModule()
[~, name, ~]  = fileparts(pwd);
if exist('initCodeGen_V3.m', 'file')
    module_name = name;
else
    error('This does not seem to be a valid module for code genertion.')
end