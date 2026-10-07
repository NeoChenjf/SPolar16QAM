function model = build_qam_model_pmf(qam, pI, TI, pQ, TQ)
%BUILD_QAM_MODEL_PMF Build axis-independent QAM PMF from latent p/relations.
    [p_axis_I, zI] = axis_pmf_from_latent(qam.labelsI, pI, TI);
    [p_axis_Q, zQ] = axis_pmf_from_latent(qam.labelsQ, pQ, TQ);
    psym = kron(p_axis_I, p_axis_Q);
    psym = psym / sum(psym);
    z_labels = [repelem(zI, qam.MQ, 1), repmat(zQ, qam.MI, 1)];
    if isempty(TI), TI = eye(qam.mI); end
    if isempty(TQ), TQ = eye(qam.mQ); end
    model = struct('p_axis_I', p_axis_I, 'p_axis_Q', p_axis_Q, ...
        'psym', psym, 'z_labels', z_labels, 'TI', TI, 'TQ', TQ);
end
