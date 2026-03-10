function A5 = stack_subjects_5D(C, dataCol)
    nSubj = numel(C);
    X0 = C{1}{dataCol};                % [T x Ch x S x Tr]
    [T,Ch,S,Tr] = size(X0);
    for s = 1:nSubj
        assert(isequal(size(C{s}{dataCol}), [T,Ch,S,Tr]), ...
            'Subjects have mismatched data sizes.');
    end
    A5 = NaN(T,Ch,S,Tr,nSubj, 'like', X0);  % [T x Ch x S x Tr x Subj]
    for s = 1:nSubj
        A5(:,:,:,:,s) = C{s}{dataCol};
    end
end
