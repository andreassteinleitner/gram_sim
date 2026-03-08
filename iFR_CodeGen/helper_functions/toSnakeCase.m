function retval = toSnakeCase(str)
retval = '';
str = strrep(str, '-', '_');
str = strrep(str, ' ', '_');
idx = isstrprop(str, 'upper');
for i=1:length(str)
    if idx(i) == 0
        retval(end+1) = str(i);
    else
        if i == 1
            retval(end+1) = lower(str(i));
        else
            retval(end+1:end+2) = ['_' lower(str(i))];
        end
    end
end
end