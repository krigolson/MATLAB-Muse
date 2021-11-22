function [event, eeg] = readMuse(chData)

    % convert muse data that is read into the event index and the EEG
    % each muse raw sample contains 18 values which represent 12 chunks of
    % 12 bit data. so, every three 8 bit bytes represents two 12 bit bytes.
    % the code below sorts this out and returns 12 EEG samples

    % set up zero arrays for the index and the raw EEG data
    rawEventIndex = zeros(1,2);
    rawEEGData = zeros(1,18);

    % set up zero arrays for the bytes
    byte1 = zeros(1,8);
    byte2 = zeros(1,8);
    byte3 = zeros(1,8);

    % set up zero array for eeg sample
    eegSample = zeros(1,12);

    % get the index which is the first two values
    rawEventIndex = chData(1:2);
    % get the EEG in binary format which is the next 18 values
    rawEEGData = chData(3:20);

    % convery the index by using bitshift
    event = bitshift(rawEventIndex(1), 8) + rawEventIndex(2);

    w = 1;
    q = 1;
    % need to loop through the 18 values in groups of 3, so we process 3
    % each iteration and loop 6 times
    for i = 1:6
        % so basically you have to turn the incoming data into 12 but
        % numbers
        % grab three bytes which is two 12 bit numbers
        byte1 = de2bi(rawEEGData(w),8);
        byte2 = de2bi(rawEEGData(w+1),8);
        byte3 = de2bi(rawEEGData(w+2),8);
        % define each of the two 12 bit numbers
        eegSample(q) = bi2de([byte2(5:8) byte1]);
        eegSample(q+1) = bi2de([byte3 byte2(1:4)]);
        % move the indexes
        q = q + 2;
        w = w + 3;
    end
    
    % conversion factors to get results in microvolts
    eeg = 0.48828125 * (eegSample - hex2dec('0X800'));

end

