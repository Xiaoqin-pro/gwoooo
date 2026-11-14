function value = cec2022_objective(x, functionId)
%CEC2022_OBJECTIVE Scalar adapter for the bundled CEC2022 MEX function.
value = cec22_test_func(x(:), functionId);
if ~isscalar(value) || ~isreal(value) || ~isfinite(value)
    error('cec2022_objective:Output', ...
        'CEC2022 MEX must return one finite real value for a single candidate.');
end
value = double(value);
end
