function retval = toUpperCamelCase(str)
retval = '';
idx = strfind(str, '_');
idx = [idx strfind(str, '-')];
idx = [idx strfind(str, ' ')];
shift=0;
for i=1:length(str)
    if i+shift <= length(str)
        if ~any(idx==i+shift)
            retval(end+1) = str(i+shift);
        else
            shift=shift+1;
            retval(end+1) = upper(str(i+shift));
        end
    end
end
retval(1) = upper(retval(1));
end