function [event, eeg] = readMuse(chData)

    % convert muse data that is read into the event index and the EEG
    % each muse raw sample contains 18 values which represent 12 chunks of
    % 12 bit data. so, every three 8 bit bytes represents two 12 bit bytes.
    % the code below sorts this out and returns 12 EEG samples

    rawEventIndex = zeros(1,2);
    rawEEGData = zeros(1,18);

    byte1 = zeros(1,8);
    byte2 = zeros(1,8);
    byte3 = zeros(1,8);
    eegSample = zeros(1,12);

    rawEventIndex = chData(1:2);
    rawEEGData = chData(3:20);

    event = bitshift(rawEventIndex(1), 8) + rawEventIndex(2);

    w = 1;
    q = 1;
    for i = 1:6
        byte1 = de2bi(rawEEGData(w),8);
        byte2 = de2bi(rawEEGData(w+1),8);
        byte3 = de2bi(rawEEGData(w+2),8);
        eegSample(q) = bi2de([byte2(5:8) byte1]);
        eegSample(q+1) = bi2de([byte3 byte2(1:4)]); 
        q = q + 2;
        w = w + 3;
    end

    eeg = 0.48828125 * (eegSample - hex2dec('0X800'));

end

