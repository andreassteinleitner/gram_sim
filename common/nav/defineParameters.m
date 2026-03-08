function varargout =defineParameters(varargin)
    % Determine the number of outputs expected
    nOut = max(nargout, 1); % Ensure at least one output is handled

    % Preallocate varargout
    varargout = cell(1, nOut);
    
    result = defineParameters_nav(varargin{:});

    % Set the outputs
    varargout{1} = result;
        
    % If more outputs are requested, set them
    for k = 2:nargout
        varargout{k} = result * k;
    end
end