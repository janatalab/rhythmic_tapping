function outData = background_responses(inData,params)
%
% right now this function just calculates percentage of subs with
% >=2 and >=5 yrs musical training. It can be expanded later to do more

form_name_defs;

%clear searchCrit;
%searchCrit.name = 'response_data';
%respIdx = ensemble_find_analysis_struct(inData,searchCrit);
%respInfo =inData{respIdx};
respInfo = inData;
respInfoCols = set_var_col_const(respInfo.vars);

bgdFormName = 'MUSIC_BKGND_V1';
bgdFormID = form_id_const.(bgdFormName);
yrsTrainQID = 7;


clear tmpFilt;
tmpFilt.include.all.form_id = bgdFormID;
tmpFilt.include.all.question_id = yrsTrainQID;
bkdResps = ensemble_filter(respInfo,tmpFilt);

numYrs = str2num(char(bkdResps.data{end}));

gt2 = sum(numYrs >=2);
gt5 = sum(numYrs >=5);




outData = [];


return
