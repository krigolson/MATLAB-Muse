function [waveletData] = doMuseWavelet(eegData)

% doMuseWavelet performs the wavelet transformation on a single chunk of
% Muse data
% O. Krigolson

minimumFrequency = 1;
maximumFrequency = 30;
frequencySteps = 60;
mortletParameter = 6;
samplingRate = 256;

% the y-vector for plots showing the frequency range
frequencyResolution = linspace(minimumFrequency,maximumFrequency,frequencySteps); % Linear scale

% used in creating the actual wavelet
s = logspace(log10(mortletParameter(1)),log10(mortletParameter(end)),frequencySteps) ./ (2*pi*frequencyResolution);

% length of the wavelet kernel, why -2 to 2??? WHY? MAYBE length of wavelet = 2 x sampling rate
waveletTime = -2:1/samplingRate:2;

% middle of the wavelet - but also the length of the zero padding
middleWavelet = (length(waveletTime)-1)/2;

% length of the wavelet
lengthWavelet = length(waveletTime);

% length of data in the analysis when it is concatenated
lengthData = size(eegData,2);

% this is the length of the convolution, data plus size of wavelet
lengthConvolution = lengthWavelet + lengthData - 1;

% cycle through the channels
for channelCounter = 1:size(eegData,1)
    
    % concatenate all the trials to help with edge artifacts (maybe?) and improve
    % processing speed (how much?)
    channelData = zeros(1,size(eegData,2));
    channelData = eegData(channelCounter,:);
    
    % run the FFT on the EEG data, use nConv, adds in zero padding as
    fftData = fft(channelData,lengthConvolution);
    
    % initialize output time-frequency data
    timeFrequencyData = zeros(length(frequencyResolution),size(eegData,2));
    
    % now perform convolutions and loop over frequencies
    for fi=1:length(frequencyResolution)
        
        % create wavelet and get its FFT - the wavelets is a combination of
        % Eulers waveform (first half) and the Gaussian (second half)
        wavelet  = exp(2*1i*pi*frequencyResolution(fi).*waveletTime) .* exp(-waveletTime.^2./(2*s(fi)^2));
        
        % take the fft of the wavelet
        fftWavelet = fft(wavelet,lengthConvolution);
        
        % this standardizes the wavelet between 0 and 1
        fftWavelet = fftWavelet ./ max(fftWavelet);
        
        % now run convolution in one step - what is put into the fft is not the
        % dot the product of the EEG data and the wavelet, it is the dot
        % product of the fft of the EEG data and the wavelet - it is an inverse
        % fft as the two things going in are ffts already
        waveletOutput = ifft(fftWavelet .* fftData);
        
        % cuts off half the wavlet from the start, and half from the end, the
        % bits that were zero padded in the first place, not the transpose
        % at the end to orient time on X axis
        waveletOutput = waveletOutput(middleWavelet+1:end-middleWavelet)';
                
        % compute power and average over trials
        timeFrequencyData(fi,:) = mean(abs(waveletOutput).^2,2);
    end
    
    % assign output variable, note wavelet output is 3D - channels x time x
    % frequency
    waveletData(channelCounter,:,:) = timeFrequencyData;

end

end