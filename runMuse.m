function runMuse(what)

    global endCollection

    fftTotal = matlabMuse2(what);

    if what == 2

        avgFFT = mean(fftTotal,1);
    
        figure;
    
        bar(avgFFT);
    
        delta = mean(avgFFT(1:3));
    
        theta = mean(avgFFT(4:7));
    
        alpha = mean(avgFFT(8:12));
    
        beta = mean(avgFFT(13:30));
    
        disp(['Delta Power is ' num2str(delta)]);
    
        disp(['Theta Power is ' num2str(theta)]);
    
        disp(['Alpha Power is ' num2str(alpha)]);
    
        disp(['Beta Power is ' num2str(beta)]);

    end

end