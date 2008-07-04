function stim_attributes = stimAttributes(inData,params)

SILENCE_STIM_ID = 6497;

%build a stim/groove attribute data struct
lowGrooveAttributeID = mysql_extract_data('table','attribute', ...
					     'name','real_music_low_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);
midGrooveAttributeID = mysql_extract_data('table','attribute', ...
					     'name','real_music_mid_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);
highGrooveAttributeID = mysql_extract_data('table','attribute', ...
					      'name','real_music_high_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);

stim_attributesData = mysql_extract_data('table','stimulus_x_attribute','attribute_id',[lowGrooveAttributeID{1},midGrooveAttributeID{1},highGrooveAttributeID{1}],'conn_id',params.ensemble.conn_id,'extract_flds',{'stimulus_id','attribute_id'});


stim_attributes = ensemble_init_data_struct;
stim_attributes.vars = {'stimulus_id','stim_cat'};
stim_attributesCols = set_var_col_const(stim_attributes.vars);
stim_attributes.data{stim_attributesCols.stimulus_id} = ...
    stim_attributesData{1};
stim_attributes.data{stim_attributesCols.stim_cat}(stim_attributesData{2} ==  lowGrooveAttributeID{1},1) = {'low_groove'};
stim_attributes.data{stim_attributesCols.stim_cat}(stim_attributesData{2} == ...
					       midGrooveAttributeID{1},1) = {'mid_groove'};
stim_attributes.data{stim_attributesCols.stim_cat}(stim_attributesData{2} == ...
					       highGrooveAttributeID{1},1) = {'high_groove'};

stim_attributes.data{stim_attributesCols.stimulus_id}(end+1) = ...
    SILENCE_STIM_ID;
stim_attributes.data{stim_attributesCols.stim_cat}{end+1} = 'silence';
