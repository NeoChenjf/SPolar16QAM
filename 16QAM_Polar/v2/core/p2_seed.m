function value = p2_seed(purpose, seed, realization, snr_index, frame, group)
%P2_SEED Collision-free mixed-radix keys in the registered experiment domain.
% Cases intentionally omitted: paired controls share base messages and noise.
    roles={'power_calibration','power_validation','pilot','model_calibration', ...
        'test_seen','test_unseen','pmf','singlecarrier'};
    seeds={[8101,8102,8103],[8201,8202,8203,8211,8212,8213,8221,8222,8223,8231,8232,8233], ...
        8301,8401,8501,8601,[8701,8702,8703],8801};
    role=find(strcmp(roles,purpose)); assert(isscalar(role),'Unknown purpose.');
    slot=find(seeds{role}==seed); assert(isscalar(slot),'Seed not registered for purpose.');
    validateattributes(realization,{'numeric'},{'scalar','integer','>=',0,'<=',31});
    validateattributes(snr_index,{'numeric'},{'scalar','integer','>=',0,'<=',15});
    validateattributes(frame,{'numeric'},{'scalar','integer','>=',0,'<=',8191});
    validateattributes(group,{'numeric'},{'scalar','integer','>=',0,'<=',7});
    role_index=role-1;
    if role==2 && slot>3
        role_index=7+floor((slot-1)/3); slot=mod(slot-1,3)+1;
    end
    value=group+8*frame+65536*snr_index+1048576*realization ...
        +33554432*(slot-1)+134217728*role_index;
end
