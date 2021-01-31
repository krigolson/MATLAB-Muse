function outputCoefficients = doMuseFFT(data,sRate)

    resolution = sRate/size(data,2);

    coefficients = fft(data,[],2);
    coefficients = coefficients/length(coefficients);
    coefficients = abs(coefficients);
    coefficients(:,1) = [];
    coefficients(:,61:end) = [];
    coefficients = (coefficients * 2);
    
    % scale to 1 Hz per bin
    outputCoefficients(1,:) = mean(reshape(coefficients(1,:), 1/resolution, []));
    outputCoefficients(2,:) = mean(reshape(coefficients(2,:), 1/resolution, []));
    outputCoefficients(3,:) = mean(reshape(coefficients(3,:), 1/resolution, []));
    outputCoefficients(4,:) = mean(reshape(coefficients(4,:), 1/resolution, []));

end

