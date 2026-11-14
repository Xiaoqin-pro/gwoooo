function projectRoot = gwo_project_root()
%GWO_PROJECT_ROOT Resolve the project root when this file lives in code/.
codeRoot=fileparts(mfilename('fullpath'));
projectRoot=fileparts(codeRoot);
if ~isfolder(fullfile(projectRoot,'results')) || ~isfolder(fullfile(projectRoot,'data'))
    error('gwo_project_root:Layout','Expected project root to contain results/ and data/.');
end
end
